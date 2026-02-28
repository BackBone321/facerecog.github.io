let model, webcam;

async function initTeachable() {
    const URL = "./assets/model/"; // path to model.json
    model = await tmImage.load(URL + "model.json", URL + "metadata.json");

    webcam = new tmImage.Webcam(400, 300);
    await webcam.setup();
    await webcam.play();

    document.getElementById("webcam-container").appendChild(webcam.canvas);
    window.requestAnimationFrame(loop);
}

async function loop() {
    webcam.update();
    window.requestAnimationFrame(loop);
}

async function predictFromTeachable() {
    const prediction = await model.predict(webcam.canvas);
    let highest = prediction.reduce((a, b) => a.probability > b.probability ? a : b);
    alert("Prediction: " + highest.className + " - " + (highest.probability*100).toFixed(2) + "%");
}

window.onload = initTeachable;
window.predictFromTeachable = predictFromTeachable;