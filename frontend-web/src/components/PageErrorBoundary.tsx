import { Component, ErrorInfo, ReactNode } from 'react';

export class PageErrorBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false };
  static getDerivedStateFromError() { return { failed: true }; }
  componentDidCatch(_error: Error, _info: ErrorInfo) {
    // Do not expose component state, tokens or server details to the error screen.
    console.error('A page could not be rendered. Reload to recover.');
  }
  render() {
    if (this.state.failed) return <main className="account-page" role="alert"><h1>This page could not open</h1><p>Reload to try again. If you were saving a change, check its status before submitting again.</p><button className="btn btn-primary" onClick={() => window.location.reload()}>Reload page</button><a className="btn btn-secondary" href="/">Return home</a></main>;
    return this.props.children;
  }
}
