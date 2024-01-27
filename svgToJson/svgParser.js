function parseDetails() {
  let outputJson = { circles: {}, paths: {} };
  outputJson = parseCircles(outputJson);
  outputJson = parsePaths(outputJson);

  console.log(outputJson);
  document.getElementById("outputJson").innerHTML = JSON.stringify(outputJson);
}

function parseCircles(outputJson) {
  const circles = document.querySelectorAll("circle");

  for (let circle of circles) {
    const circleData = {
      cx: circle.cx.baseVal.value,
      cy: circle.cy.baseVal.value,
      r: circle.r.baseVal.value,
    };
    outputJson.circles[circle.id] = circleData;
  }

  return outputJson;
}

function parsePaths(outputJson) {
  const paths = document.querySelectorAll("path");

  for (let path of paths) {
    const d = path.attributes.d.value;
    const values = d.split(" ");

    if (values.length < 3) continue;
    const pathData = {
      point1: values[1].split(","),
      point2: values[2].split(","),
    };
    outputJson.paths[path.id] = pathData;
  }

  return outputJson;
}

parseDetails();
