//! Keeping the bar visible *inside* the Windows taskbar.
//!
//! Sitting in the taskbar's own strip, in the empty space beside the pinned
//! icons, is purely a matter of position — the hard part is z-order. The taskbar
//! is a topmost window and so is the bar, and among topmost windows the one
//! activated most recently is drawn on top. Clicking the taskbar or opening
//! Start therefore buries the bar behind it, which is exactly what "always on
//! top" looked like it should have prevented.
//!
//! Windows offers no "stay above the taskbar" flag, so the bar re-claims the top
//! of the topmost band on a timer. Being covered for up to a second after
//! clicking Start is the cost of that approach. The alternative — reparenting
//! the window into the taskbar with `SetParent` — draws inside the taskbar for
//! real, but hands the window's lifetime to Explorer and takes the bar down with
//! every Explorer restart.

use std::ffi::c_void;

use windows::core::{w, PCWSTR};
use windows::Win32::Foundation::{HWND, RECT};
use windows::Win32::Graphics::Dwm::{DwmGetWindowAttribute, DWMWA_EXTENDED_FRAME_BOUNDS};
use windows::Win32::UI::WindowsAndMessaging::{
    FindWindowW, GetWindowRect, SetWindowPos, HWND_TOPMOST, SWP_NOACTIVATE, SWP_NOMOVE, SWP_NOSIZE,
};

/// `HWND` wraps a raw pointer and so is not `Send`. The pinning watchdog runs on
/// its own thread, so handles travel as `isize` and are rebuilt here.
fn as_hwnd(raw: isize) -> HWND {
    HWND(raw as *mut c_void)
}

/// Screen rectangle of the taskbar itself, which is where the bar has to land.
/// Read live rather than derived from the work area: the two disagree when the
/// taskbar is set to auto-hide, and the taskbar's own rectangle is the one that
/// matters for drawing on top of it.
pub fn taskbar_rect() -> Option<RECT> {
    let hwnd = unsafe { FindWindowW(w!("Shell_TrayWnd"), PCWSTR::null()) }.ok()?;
    let mut rc = RECT::default();
    unsafe { GetWindowRect(hwnd, &mut rc) }.ok()?;
    Some(rc)
}

/// Re-claim the top of the topmost band. Cheap enough to call on a short timer:
/// when the bar is already on top this is a no-op inside the window manager.
///
/// `SWP_NOACTIVATE` matters — without it, raising the bar would steal focus from
/// whatever the user is typing into.
pub fn raise_above_taskbar(raw: isize) {
    let _ = unsafe {
        SetWindowPos(
            as_hwnd(raw),
            Some(HWND_TOPMOST),
            0,
            0,
            0,
            0,
            SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE,
        )
    };
}

/// Where the bar's *painted* top edge belongs so it sits centred in the taskbar
/// strip. A bar taller than the taskbar is pinned to the strip's top edge rather
/// than being pushed up off it.
pub fn centered_top(taskbar_top: i32, taskbar_height: i32, bar_height: i32) -> i32 {
    taskbar_top + (taskbar_height - bar_height).max(0) / 2
}

/// Distance between the top of the window frame and the top of the pixels the
/// window actually paints.
///
/// Windows keeps invisible resize borders around a borderless window, so the
/// frame rectangle that `SetWindowPos` positions is larger than the visible bar.
/// Aligning the frame to the taskbar would therefore leave the bar sitting a few
/// pixels low; this measures the discrepancy instead of assuming it, since it
/// varies with DPI and Windows version.
pub fn frame_inset_top(raw: isize) -> i32 {
    let hwnd = as_hwnd(raw);

    let mut frame = RECT::default();
    if unsafe { GetWindowRect(hwnd, &mut frame) }.is_err() {
        return 0;
    }

    let mut painted = RECT::default();
    let queried = unsafe {
        DwmGetWindowAttribute(
            hwnd,
            DWMWA_EXTENDED_FRAME_BOUNDS,
            &mut painted as *mut RECT as *mut c_void,
            std::mem::size_of::<RECT>() as u32,
        )
    };
    if queried.is_err() {
        return 0;
    }

    painted.top - frame.top
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bar_centers_in_a_taller_taskbar() {
        // 48px Windows 11 taskbar, 40px bar → 4px of breathing room either side.
        assert_eq!(centered_top(1032, 48, 40), 1036);
    }

    #[test]
    fn bar_sits_flush_when_it_matches_the_taskbar() {
        // 40px Windows 10 taskbar, 40px bar → exactly flush.
        assert_eq!(centered_top(1040, 40, 40), 1040);
    }

    #[test]
    fn bar_taller_than_the_taskbar_pins_to_the_top_edge() {
        // An expanded panel must not be pushed up off the strip.
        assert_eq!(centered_top(1040, 40, 180), 1040);
    }
}
