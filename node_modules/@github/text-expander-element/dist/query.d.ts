declare type Query = {
    text: string;
    position: number;
};
declare type QueryOptions = {
    lookBackIndex: number;
    multiWord: boolean;
    lastMatchPosition: number | null;
};
export default function query(text: string, key: string, cursor: number, { multiWord, lookBackIndex, lastMatchPosition }?: QueryOptions): Query | void;
export {};
