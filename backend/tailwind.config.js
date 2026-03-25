/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{html,erb}',
    './app/javascript/**/*.{js,jsx}',
    './app/helpers/**/*.rb',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"DM Sans"', 'sans-serif'],
      },
      colors: {
        credal: {
          purple: '#6D46DE',
          'purple-dark': '#5A35C4',
          green: '#00C14E',
          black: '#25262B',
          'dark-gray': '#333333',
          'medium-gray': '#555555',
          'light-gray': '#777777',
          warm: '#FAF5F3',
          red: '#B3014D',
          'deep-purple': '#381C88',
        },
      },
      borderRadius: {
        'pill': '64px',
      },
      boxShadow: {
        'credal': '0px 4px 14px rgba(0, 0, 0, 0.04)',
      },
    },
  },
  plugins: [require('@tailwindcss/forms')],
}
