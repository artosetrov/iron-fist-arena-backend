'use client'

import React from 'react'

interface ErrorBoundaryProps {
  children: React.ReactNode
  /** Optional custom fallback UI. Receives the error and a reset callback. */
  fallback?: (props: { error: Error; reset: () => void }) => React.ReactNode
}

interface ErrorBoundaryState {
  error: Error | null
}

/**
 * Reusable React error boundary that catches render-time errors in its
 * subtree and displays a friendly message with a retry button.
 *
 * Usage:
 *   <ErrorBoundary>
 *     <SomeComponent />
 *   </ErrorBoundary>
 *
 * Or with a custom fallback:
 *   <ErrorBoundary fallback={({ error, reset }) => <MyFallback ... />}>
 *     <SomeComponent />
 *   </ErrorBoundary>
 */
export class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { error: null }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    // Log to console so it shows up in server/browser logs.
    console.error('[ErrorBoundary] Caught error:', error, errorInfo)
  }

  handleReset = () => {
    this.setState({ error: null })
  }

  render() {
    const { error } = this.state

    if (error) {
      // Allow a custom fallback if the consumer provides one.
      if (this.props.fallback) {
        return this.props.fallback({ error, reset: this.handleReset })
      }

      // Default fallback UI
      return (
        <div className="flex flex-col items-center justify-center gap-4 rounded-lg border border-red-200 bg-red-50 p-8 text-center dark:border-red-800 dark:bg-red-950">
          <div className="text-red-600 dark:text-red-400">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="mx-auto h-10 w-10"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>

          <h3 className="text-lg font-semibold text-red-700 dark:text-red-300">
            Something went wrong
          </h3>

          <p className="max-w-md text-sm text-red-600 dark:text-red-400">
            {error.message || 'An unexpected error occurred while rendering this section.'}
          </p>

          <button
            type="button"
            onClick={this.handleReset}
            className="mt-2 rounded-md bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 dark:bg-red-700 dark:hover:bg-red-600"
          >
            Try again
          </button>
        </div>
      )
    }

    return this.props.children
  }
}

export default ErrorBoundary
