function init(data) {
  document.getElementById("waiting").style.visibility = "hidden";
  cases = data.cases;
  parties = data.parties;
  new Timeliner().plot(cases, parties);
};

d3.json("/communication", init)