export default {
  mounted() {
    if (this.el.dataset.state === "on") {
      window.Telegram.WebApp.BackButton.onClick(() => {
        this.pushEvent("back")
      })

      window.Telegram.WebApp.BackButton.show()
    } else {
      window.Telegram.WebApp.BackButton.hide()
    }
  }
}