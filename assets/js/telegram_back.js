export default {
  mounted() {
    if (this.el.dataset.state === "on") {
      window.Telegram.WebApp.BackButton.onClick(() => {
        window.history.back()
      })

      window.Telegram.WebApp.BackButton.show()
    } else {
      window.Telegram.WebApp.BackButton.hide()
    }
  }
}