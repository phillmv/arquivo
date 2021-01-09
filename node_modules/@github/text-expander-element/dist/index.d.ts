import TextExpanderElement from './text-expander-element';
export { TextExpanderElement as default };
declare global {
    interface Window {
        TextExpanderElement: typeof TextExpanderElement;
    }
}
