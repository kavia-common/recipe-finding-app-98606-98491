import React from 'react'
import { render, screen } from '@testing-library/react'
import '@testing-library/jest-dom'
import App from './App'

test('renders app root', () => {
  render(<App />)
  expect(screen.getByTestId('app-root')).toHaveTextContent('App')
})
