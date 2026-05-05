type SessionInvalidListener = () => void;

let sessionInvalidListener: SessionInvalidListener | null = null;

export const authSessionEvents = {
  setSessionInvalidListener(fn: SessionInvalidListener | null) {
    sessionInvalidListener = fn;
  },

  notifySessionInvalid() {
    sessionInvalidListener?.();
  },
};
