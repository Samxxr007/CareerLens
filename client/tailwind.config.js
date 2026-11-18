/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          900: '#17324D',
          800: '#1E4064',
          700: '#25507D',
        },
        brand: {
          blue: '#1E6091',
          teal: '#06A88A',
          bg: '#F6F8FA',
          surface: '#FFFFFF',
          border: '#E3E8EF',
          textPrimary: '#182433',
          textSecondary: '#687789',
          success: '#16865D',
          warning: '#D98C21',
          danger: '#D64545',
        }
      }
    },
  },
  plugins: [],
}
