document.addEventListener("DOMContentLoaded", function () {
    const config = {
        StandardEyeIcon: "fas fa-eye",
        StandardColor: "white",
        SuccessColor: "#DC143C",
    };

    const targetEye = document.getElementById("target-eye");
    let targetLabel = document.getElementById("target-label");
    let TargetEyeStyleObject = targetEye.style;

    function OpenTarget() {
        targetLabel.innerHTML = "";
        targetEye.style.display = "block";
        targetEye.className = config.StandardEyeIcon;
        TargetEyeStyleObject.color = config.StandardColor;
    }

    function CloseTarget() {
        targetLabel.innerHTML = "";
        targetEye.style.display = "none";
    }

    function FoundTarget(item) {
        if (item.data) {
            targetEye.className = item.data;
        }
        TargetEyeStyleObject.color = config.SuccessColor;
        targetLabel.innerHTML = "";
        for (let [index, itemData] of Object.entries(item.options)) {
            if (itemData !== null) {
                index = Number(index) + 1;
                targetLabel.innerHTML += `<div id="target-option-${index}" style="margin-bottom: 0.2vh;
                border-radius: 0.15rem; padding: 0.45rem; background: rgba(23, 23, 23, 40%);
                color: ${config.StandardColor}"><span id="target-icon-${index}"><i class="${itemData.icon}"></i> </span>${itemData.label}</div>`;
            }
        }
    }

    function ValidTarget(item) {
        targetLabel.innerHTML = "";
        for (let [index, itemData] of Object.entries(item.data)) {
            if (itemData !== null) {
                index = Number(index) + 1;
                targetLabel.innerHTML += `<div id="target-option-${index}" style="margin-bottom: 0.2vh;
                border-radius: 0.15rem; padding: 0.45rem; background: rgba(23, 23, 23, 40%);
                color: ${config.StandardColor}"><span id="target-icon-${index}"><i class="${itemData.icon}"></i> </span>${itemData.label}</div>`;
            }
        }
    }

    function LeftTarget() {
        targetLabel.innerHTML = "";
        TargetEyeStyleObject.color = config.StandardColor;
        targetEye.className = config.StandardEyeIcon;
    }

    function handleMouseDown(event) {
        let element = event.target;
        if (element.id) {
            const split = element.id.split("-");
            if (split[0] === "target" && split[1] !== "eye" && event.button == 0) {
                fetch(`https://${GetParentResourceName()}/selectTarget`, {
                    method: "POST",
                    headers: { "Content-Type": "application/json; charset=UTF-8" },
                    body: JSON.stringify(split[2]),
                });
                targetLabel.innerHTML = "";
            }
        }
        if (event.button == 2) {
            LeftTarget();
            fetch(`https://${GetParentResourceName()}/leftTarget`, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: "",
            });
        }
    }

    function handleKeyDown(event) {
        if (event.key == "Escape" || event.key == "Backspace") {
            CloseTarget();
            fetch(`https://${GetParentResourceName()}/closeTarget`, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: "",
            });
        }
    }

    function handleMouseOver(event) {
        const element = event.target;
        if (element.id) {
            const split = element.id.split("-");
            if (split[0] === "target" && split[1] === "option") {
                element.style.transform = "translateX(10px)";
                element.style.transition = "transform 0.3s ease";
            }
        }
    }

    function handleMouseOut(event) {
        const element = event.target;
        if (element.id) {
            const split = element.id.split("-");
            if (split[0] === "target" && split[1] === "option") {
                element.style.transform = "translateX(0)";
            }
        }
    }

    window.addEventListener("message", function (event) {
        switch (event.data.response) {
            case "openTarget":
                OpenTarget();
                break;
            case "closeTarget":
                CloseTarget();
                break;
            case "foundTarget":
                FoundTarget(event.data);
                break;
            case "validTarget":
                ValidTarget(event.data);
                break;
            case "leftTarget":
                LeftTarget();
                break;
        }
    });

    window.addEventListener("mousedown", handleMouseDown);
    window.addEventListener("keydown", handleKeyDown);
    window.addEventListener("mouseover", handleMouseOver);
    window.addEventListener("mouseout", handleMouseOut);

    window.addEventListener("unload", function () {
        window.removeEventListener("mousedown", handleMouseDown);
        window.removeEventListener("keydown", handleKeyDown);
        window.removeEventListener("mouseover", handleMouseOver);
        window.removeEventListener("mouseout", handleMouseOut);
    });
});
