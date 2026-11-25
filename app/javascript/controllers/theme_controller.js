import { Controller } from "@hotwired/stimulus"

// Tema claro u oscuro con data-bs-theme de Bootstrap 5.3.
// La preferencia es solo visual: se guarda en localStorage (lo permite el
// enunciado). Nada del juego (puntos, partidas) va a localStorage.
export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.apply(this.saved() || this.systemTheme())
  }

  toggle() {
    const next = document.documentElement.dataset.bsTheme === "dark" ? "light" : "dark"
    this.apply(next)
    try { localStorage.setItem("theme", next) } catch (e) {}
  }

  apply(theme) {
    document.documentElement.dataset.bsTheme = theme
    if (this.hasIconTarget) {
      this.iconTarget.className = theme === "dark" ? "bi bi-sun" : "bi bi-moon-stars"
    }
  }

  saved() {
    try { return localStorage.getItem("theme") } catch (e) { return null }
  }

  systemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }
}
