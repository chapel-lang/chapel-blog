/* A sticky table of contents lands us in hot water if the user's viewport is
   too small to fit the TOC. Then, as they keep scrolling, the TOC keeps
   up with them, and its bottom remains unreachable. A coarse solution
   is to always keep the TOC at the top when the viewport is too small. */
function unstickToc(toc, viewport) {
    const wrapper = toc.querySelector('.wrapper');
    if (!wrapper) return;

    if (wrapper.offsetHeight > viewport - 50 && !wrapper.classList.contains('overfull')) {
        wrapper.classList.add('overfull');
    } else if (wrapper.offsetHeight <= viewport - 50 && wrapper.classList.contains('overfull')) {
        wrapper.classList.remove('overfull');
    }
}
document.addEventListener('DOMContentLoaded', function() {
    var toc = document.querySelector('.table-of-contents.sticky');
    if (!toc) return;

    window.addEventListener('resize', function() {
        unstickToc(toc, window.innerHeight);
    });
    unstickToc(toc, window.innerHeight);
});
