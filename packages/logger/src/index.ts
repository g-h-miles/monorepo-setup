declare const log: {
    (...args: unknown[]): void;
    info(...args: unknown[]): void;
    warn(...args: unknown[]): void;
    error(...args: unknown[]): void;
    success(...args: unknown[]): void;
    debug(...args: unknown[]): void;
};

export { log };
