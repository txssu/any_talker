console.log( window.Telegram.WebApp.initData)

fetch("/log_in/via_webapp?" + window.Telegram.WebApp.initData)
    .then(response => response.text())
    .then(data => {
        if (data === "ERROR") {
            console.error("Failed to authenticate.")
            return
        }
        location.href = "/webapp"
    })

