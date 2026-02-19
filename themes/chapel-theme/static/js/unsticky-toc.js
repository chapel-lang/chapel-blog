/* A sticky table of contents lands us in hot water if the user's viewport is
   too small to fit the TOC. Then, as they keep scrolling, the TOC keeps
   up with them, and its bottom remains unreachable. A coarse solution
   is to always keep the TOC at the top when the viewport is too small.
   However, this leads to jumping around if the user shrinks the window.
   Instead, when the viewport gets too small, leave the TOC exactly where
   it is (possibly down the page, if the user shrinks the window after scrolling).
   This seems the least jarring to me.

   Some specifics:
   * If the window started out to small, it's not jarring to leave the TOC
     at the top, where it would start. Only pin TOC at its current position
     if it had a chance to move.
   * We don't want to assume what offset is set in CSS by the 'top' property.
     So, the first time we need to override, save it in a CSS variable,
     and restore it when we can make the TOC sticky again. */
function unstickToc(toc, viewport, first) {
    const wrapper = toc.querySelector('.wrapper');
    if (!wrapper) return;

    if (wrapper.offsetHeight > viewport - 50 && !wrapper.classList.contains('overfull')) {
        console.log('TOC is taller than viewport, making it unsticky');
        var newTop;
        if (first) {
            // The page started too small to sticky the TOC, so pin it at
            // the top where it would start.
            newTop = '0px';
        } else {
            newTop = (wrapper.getBoundingClientRect().top - toc.getBoundingClientRect().top) + 'px';
        }
        wrapper.style.setProperty('--previous-top', wrapper.style.top);
        wrapper.style.top = newTop;
        wrapper.classList.add('overfull');
    } else if (wrapper.offsetHeight <= viewport - 50 && wrapper.classList.contains('overfull')) {
        console.log('TOC is now smaller than viewport, making it sticky again');
        wrapper.classList.remove('overfull');
        wrapper.style.top = wrapper.style.getPropertyValue('--previous-top');
        wrapper.style.removeProperty('--previous-top');
    }
}
document.addEventListener('DOMContentLoaded', function() {
    var toc = document.querySelector('.table-of-contents.sticky');
    if (!toc) return;

    console.log('Found sticky TOC, setting up resize listener');

    window.addEventListener('resize', function() {
        unstickToc(toc, window.innerHeight, false);
    });
    unstickToc(toc, window.innerHeight, true);
});
