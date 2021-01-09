export default function debounce(callback, wait = 0) {
    let timeout;
    return function (...Rest) {
        clearTimeout(timeout);
        timeout = window.setTimeout(() => {
            clearTimeout(timeout);
            callback(...Rest);
        }, wait);
    };
}
