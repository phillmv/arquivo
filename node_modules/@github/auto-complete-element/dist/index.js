import Combobox from '@github/combobox-nav';

class AutocompleteEvent extends CustomEvent {
    constructor(type, init) {
        super(type, init);
        this.relatedTarget = init.relatedTarget;
    }
}

function debounce(callback, wait = 0) {
    let timeout;
    return function (...Rest) {
        clearTimeout(timeout);
        timeout = window.setTimeout(() => {
            clearTimeout(timeout);
            callback(...Rest);
        }, wait);
    };
}

const requests = new WeakMap();
function fragment(el, url) {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.setRequestHeader('Accept', 'text/fragment+html');
    return request(el, xhr);
}
function request(el, xhr) {
    const pending = requests.get(el);
    if (pending)
        pending.abort();
    requests.set(el, xhr);
    const clear = () => requests.delete(el);
    const result = send(xhr);
    result.then(clear, clear);
    return result;
}
function send(xhr) {
    return new Promise((resolve, reject) => {
        xhr.onload = function () {
            if (xhr.status >= 200 && xhr.status < 300) {
                resolve(xhr.responseText);
            }
            else {
                reject(new Error(xhr.responseText));
            }
        };
        xhr.onerror = reject;
        xhr.send();
    });
}

class Autocomplete {
    constructor(container, input, results) {
        this.container = container;
        this.input = input;
        this.results = results;
        this.combobox = new Combobox(input, results);
        this.results.hidden = true;
        this.input.setAttribute('autocomplete', 'off');
        this.input.setAttribute('spellcheck', 'false');
        this.interactingWithList = false;
        this.onInputChange = debounce(this.onInputChange.bind(this), 300);
        this.onResultsMouseDown = this.onResultsMouseDown.bind(this);
        this.onInputBlur = this.onInputBlur.bind(this);
        this.onInputFocus = this.onInputFocus.bind(this);
        this.onKeydown = this.onKeydown.bind(this);
        this.onCommit = this.onCommit.bind(this);
        this.input.addEventListener('keydown', this.onKeydown);
        this.input.addEventListener('focus', this.onInputFocus);
        this.input.addEventListener('blur', this.onInputBlur);
        this.input.addEventListener('input', this.onInputChange);
        this.results.addEventListener('mousedown', this.onResultsMouseDown);
        this.results.addEventListener('combobox-commit', this.onCommit);
    }
    destroy() {
        this.input.removeEventListener('keydown', this.onKeydown);
        this.input.removeEventListener('focus', this.onInputFocus);
        this.input.removeEventListener('blur', this.onInputBlur);
        this.input.removeEventListener('input', this.onInputChange);
        this.results.removeEventListener('mousedown', this.onResultsMouseDown);
        this.results.removeEventListener('combobox-commit', this.onCommit);
    }
    onKeydown(event) {
        if (event.key === 'Escape' && this.container.open) {
            this.container.open = false;
            event.stopPropagation();
            event.preventDefault();
        }
        else if (event.altKey && event.key === 'ArrowUp' && this.container.open) {
            this.container.open = false;
            event.stopPropagation();
            event.preventDefault();
        }
        else if (event.altKey && event.key === 'ArrowDown' && !this.container.open) {
            if (!this.input.value.trim())
                return;
            this.container.open = true;
            event.stopPropagation();
            event.preventDefault();
        }
    }
    onInputFocus() {
        this.fetchResults();
    }
    onInputBlur() {
        if (this.interactingWithList) {
            this.interactingWithList = false;
            return;
        }
        this.container.open = false;
    }
    onCommit({ target }) {
        const selected = target;
        if (!(selected instanceof HTMLElement))
            return;
        this.container.open = false;
        if (selected instanceof HTMLAnchorElement)
            return;
        const value = selected.getAttribute('data-autocomplete-value') || selected.textContent;
        this.container.value = value;
    }
    onResultsMouseDown() {
        this.interactingWithList = true;
    }
    onInputChange() {
        this.container.removeAttribute('value');
        this.fetchResults();
    }
    identifyOptions() {
        let id = 0;
        for (const el of this.results.querySelectorAll('[role="option"]:not([id])')) {
            el.id = `${this.results.id}-option-${id++}`;
        }
    }
    fetchResults() {
        const query = this.input.value.trim();
        if (!query) {
            this.container.open = false;
            return;
        }
        const src = this.container.src;
        if (!src)
            return;
        const url = new URL(src, window.location.href);
        const params = new URLSearchParams(url.search.slice(1));
        params.append('q', query);
        url.search = params.toString();
        this.container.dispatchEvent(new CustomEvent('loadstart'));
        fragment(this.input, url.toString())
            .then(html => {
            this.results.innerHTML = html;
            this.identifyOptions();
            const hasResults = !!this.results.querySelector('[role="option"]');
            this.container.open = hasResults;
            this.container.dispatchEvent(new CustomEvent('load'));
            this.container.dispatchEvent(new CustomEvent('loadend'));
        })
            .catch(() => {
            this.container.dispatchEvent(new CustomEvent('error'));
            this.container.dispatchEvent(new CustomEvent('loadend'));
        });
    }
    open() {
        if (!this.results.hidden)
            return;
        this.combobox.start();
        this.results.hidden = false;
    }
    close() {
        if (this.results.hidden)
            return;
        this.combobox.stop();
        this.results.hidden = true;
    }
}

const state = new WeakMap();
class AutocompleteElement extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        const listId = this.getAttribute('for');
        if (!listId)
            return;
        const input = this.querySelector('input');
        const results = document.getElementById(listId);
        if (!(input instanceof HTMLInputElement) || !results)
            return;
        state.set(this, new Autocomplete(this, input, results));
        results.setAttribute('role', 'listbox');
    }
    disconnectedCallback() {
        const autocomplete = state.get(this);
        if (autocomplete) {
            autocomplete.destroy();
            state.delete(this);
        }
    }
    get src() {
        return this.getAttribute('src') || '';
    }
    set src(url) {
        this.setAttribute('src', url);
    }
    get value() {
        return this.getAttribute('value') || '';
    }
    set value(value) {
        this.setAttribute('value', value);
    }
    get open() {
        return this.hasAttribute('open');
    }
    set open(value) {
        if (value) {
            this.setAttribute('open', '');
        }
        else {
            this.removeAttribute('open');
        }
    }
    static get observedAttributes() {
        return ['open', 'value'];
    }
    attributeChangedCallback(name, oldValue, newValue) {
        if (oldValue === newValue)
            return;
        const autocomplete = state.get(this);
        if (!autocomplete)
            return;
        switch (name) {
            case 'open':
                newValue === null ? autocomplete.close() : autocomplete.open();
                break;
            case 'value':
                if (newValue !== null) {
                    autocomplete.input.value = newValue;
                }
                this.dispatchEvent(new AutocompleteEvent('auto-complete-change', {
                    bubbles: true,
                    relatedTarget: autocomplete.input
                }));
                break;
        }
    }
}

if (!window.customElements.get('auto-complete')) {
    window.AutocompleteElement = AutocompleteElement;
    window.customElements.define('auto-complete', AutocompleteElement);
}

export default AutocompleteElement;
export { AutocompleteEvent };
