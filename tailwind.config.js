/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        bg: 'rgb(var(--c-bg) / <alpha-value>)',
        surface: 'rgb(var(--c-surface) / <alpha-value>)',
        ink: 'rgb(var(--c-text) / <alpha-value>)',
        muted: 'rgb(var(--c-muted) / <alpha-value>)',
        line: 'rgb(var(--c-border) / <alpha-value>)',
        primary: 'rgb(var(--c-primary) / <alpha-value>)',
        accent: 'rgb(var(--c-accent) / <alpha-value>)',
        sea: 'rgb(var(--c-sea) / <alpha-value>)',
        ok: 'rgb(var(--c-success) / <alpha-value>)',
        warn: 'rgb(var(--c-warning) / <alpha-value>)',
        danger: 'rgb(var(--c-danger) / <alpha-value>)',
      },
      borderRadius: {
        DEFAULT: '14px',
        card: '20px',
        xl2: '28px',
      },
      boxShadow: {
        card: '0 1px 2px rgb(0 0 0 / 0.04), 0 6px 20px -6px rgb(0 0 0 / 0.10)',
        lift: '0 10px 40px -12px rgb(0 0 0 / 0.28)',
      },
      fontFamily: {
        // Display para titulares, sans para todo lo demás. La pareja es lo que
        // más cambia la sensación de "esto está diseñado".
        display: ['"Bricolage Grotesque"', 'system-ui', 'sans-serif'],
        sans: ['"Inter Tight"', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      letterSpacing: {
        tightest: '-0.03em',
      },
    },
  },
  plugins: [],
}
