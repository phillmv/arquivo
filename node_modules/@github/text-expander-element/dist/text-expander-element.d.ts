declare type Key = {
    key: string;
    multiWord: boolean;
};
export default class TextExpanderElement extends HTMLElement {
    get keys(): Key[];
    connectedCallback(): void;
    disconnectedCallback(): void;
    dismiss(): void;
}
export {};
