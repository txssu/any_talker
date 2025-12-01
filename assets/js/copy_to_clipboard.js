export default {
  mounted() {
    this.el.addEventListener("click", () => {
      const text = this.el.dataset.text

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard
          .writeText(text)
          .then(() => {
            if (window.Telegram && window.Telegram.WebApp) {
              window.Telegram.WebApp.showPopup({
                title: "Успешно",
                message: "Список скопирован в буфер обмена",
                buttons: [{ type: "ok" }],
              })
            }
          })
          .catch((err) => {
            console.error("Failed to copy text: ", err)
            if (window.Telegram && window.Telegram.WebApp) {
              window.Telegram.WebApp.showPopup({
                title: "Ошибка",
                message: "Не удалось скопировать список",
                buttons: [{ type: "ok" }],
              })
            }
          })
      }
    })
  },
}
