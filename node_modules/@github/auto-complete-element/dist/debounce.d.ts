export default function debounce<T extends unknown[]>(callback: (...Rest: T) => unknown, wait?: number): (...Rest: T) => void;
