(function() {
  var Timeliner;
  Timeliner = (function() {
    function Timeliner() {
      console.info("Ignition");
    }
    Timeliner.prototype.plot = function(cases, parties) {
      var h, w;
      w = 1200;
      h = 900;
      this.highlightColor = "#fff";
      this.partyUnselectedColor = "#dcd6cd";
      this.caseUnselectedColor = "#aaa";
      this.vis = d3.select("#chart").insert("svg").attr("width", w).attr("height", h).attr("class", "timeline_container");
      window.vis = this.vis;
      this.vis.append("text").text("Point to a line to see its connections").attr("x", 0).attr("y", 2).attr("dy", ".71em").attr("id", "caseName");
      this.plotCases(cases);
      return this.plotParties(parties);
    };
    Timeliner.prototype.addPartyConnections = function(d, i, element) {
      var partyPt, self;
      d3.selectAll("line.connection").remove();
      d3.select("#caseName").text(d.name);
      d3.select(element).transition().style("fill", this.highlightColor);
      self = this;
      partyPt = self.circleToGlobalsCoords(element);
      return d3.selectAll("#correspondent_" + d.id).each(function(eD, eI) {
        var connectionClass, exchangePt, start, stop;
        exchangePt = self.circleToGlobalsCoords(this.childNodes[0]);
        if (eD.incoming) {
          start = partyPt;
          stop = exchangePt;
          connectionClass = "connection incoming";
        } else {
          start = exchangePt;
          stop = partyPt;
          connectionClass = "connection";
        }
        return window.vis.append("svg:line").attr("x1", start.x).attr("y1", start.y).attr("x2", start.x).attr("y2", start.y).style("stroke-width", 0.4).attr("class", connectionClass).transition().duration(1500).attr("x2", stop.x).attr("y2", stop.y);
      });
    };
    Timeliner.prototype.removePartyConnections = function(d, i, element) {
      return d3.select(element).transition().style("fill", this.partyUnselectedColor);
    };
    Timeliner.prototype.addExchangeConnections = function(d, i, element) {
      var self;
      d3.selectAll("line.connection").remove();
      d3.select("#caseName").text(d.title);
      d3.select(element).transition().style("fill", this.highlightColor);
      self = this;
      return d3.select(element).selectAll("g.exchange").each(function(d, i) {
        var exchangePt;
        exchangePt = self.circleToGlobalsCoords(this.childNodes[0]);
        return d3.select("#party_" + d.sender_or_recipent).each(function(dp, i) {
          var connectionClass, party, partyPt, start, stop;
          party = d3.select(this).select("circle");
          partyPt = self.circleToGlobalsCoords(party[0][0]);
          party.transition().style("fill", self.highlightColor);
          party.attr("class", "selected");
          if (d.incoming) {
            start = partyPt;
            stop = exchangePt;
            connectionClass = "connection incoming";
          } else {
            start = exchangePt;
            stop = partyPt;
            connectionClass = "connection";
          }
          return window.vis.append("svg:line").attr("x1", start.x).attr("y1", start.y).attr("x2", start.x).attr("y2", start.y).style("stroke-width", 0.4).attr("class", connectionClass).transition().duration(1500).attr("x2", stop.x).attr("y2", stop.y);
        });
      });
    };
    Timeliner.prototype.removeExchangeConnections = function(d, i, element) {
      d3.select(element).transition().style("fill", this.caseUnselectedColor);
      d3.selectAll("line.connection").transition().attr("opacity", 0).remove();
      return d3.selectAll("circle.selected").attr("class", "").transition().style("fill", "#dcd6cd");
    };
    Timeliner.prototype.plotCases = function(cases) {
      var barHeight, e, exchanges, h, m, parse, self, timelines, w, x, xAxis, y;
      m = [0, 00, 00, 40];
      w = 900 - m[1] - m[3];
      h = 500 - m[0] - m[2];
      parse = d3.time.format("%Y-%m-%d").parse;
      e = cases.length;
      x = d3.time.scale().range([0, w]);
      y = d3.scale.linear(0, cases.length).range([0, h]);
      xAxis = d3.svg.axis().scale(x).tickSize(4).tickSubdivide(true).orient("top");
      cases.forEach(function(d) {
        d.initiated_at = parse(d.initiated_at);
        return d.last_correspondance_at = parse(d.last_correspondance_at);
      });
      x.domain([
        cases[0].initiated_at, d3.max(cases, function(d) {
          return d.last_correspondance_at;
        })
      ]);
      y.domain([0, e]);
      barHeight = y(cases.length) / e * 0.7;
      timelines = this.vis.append("svg:g").attr("transform", "translate(" + m[2] + "," + m[3] + ")").attr("class", "case_canvas");
      self = this;
      cases = timelines.selectAll("g.case").data(cases).enter().append("svg:g").attr("class", "case").attr("transform", function(d, i) {
        return "translate(0," + y(i + 1) + ")";
      }).on("mouseover", function(d, i) {
        return self.addExchangeConnections(d, i, this);
      }).on("mouseout", function(d, i) {
        return self.removeExchangeConnections(d, i, this);
      }).attr("fill", "#aaa");
      cases.append("svg:rect").attr("width", function(d, i) {
        return 0;
      }).attr("x", function(d) {
        return x(d.initiated_at);
      }).attr("height", barHeight).transition().attr("width", function(d, i) {
        return x(d.last_correspondance_at) - x(d.initiated_at);
      }).delay(function(d, i) {
        return i * 10;
      });
      exchanges = cases.selectAll("g.exchanges").data(function(d) {
        return d.exchanges;
      }).enter().append("svg:g").attr("class", "exchange").attr("id", function(d) {
        return "correspondent_" + d.sender_or_recipent;
      }).attr("transform", function(d) {
        return "0,0)";
      });
      exchanges.append("svg:circle").attr("r", 1.5).attr("cx", function(d, i) {
        return x(parse(d.journal_date));
      }).attr("cy", barHeight / 2);
      return timelines.append("svg:g").attr("class", "x axis").attr("transform", "translate(0," + 0 + ")").call(xAxis);
    };
    Timeliner.prototype.plotParties = function(parties) {
      var bubble, bubbles, color, format, h, hOffset, node, self, w, wOffset;
      w = 600;
      h = 600;
      hOffset = 280;
      wOffset = 00;
      format = d3.format(",d");
      color = d3.interpolateRgb("#eee", this.highlightColor);
      bubble = d3.layout.pack().sort(null).size([w, h]);
      parties = {
        children: parties
      };
      bubbles = this.vis.append("svg:g").attr("transform", "translate(" + wOffset + "," + hOffset + ")");
      node = bubbles.selectAll("g.node").data(bubble.nodes(parties).filter(function(d) {
        return !d.children;
      })).enter().append("svg:g").attr("class", "party").attr("id", function(d) {
        return "party_" + d.id;
      }).attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
      });
      node.append("svg:title").text(function(d) {
        return d.name + ": " + format(d.value);
      });
      self = this;
      node.append("svg:circle").attr("r", function(d) {
        return 0;
      }).style("fill", this.partyUnselectedColor).on("mouseover", function(d, i) {
        return self.addPartyConnections(d, i, this);
      }).on("mouseout", function(d, i) {
        return self.removePartyConnections(d, i, this);
      }).transition().duration(100).attr("r", function(d) {
        return d.r * 0.9;
      }).delay(function(d, i) {
        return i * 3;
      });
      return node.append("svg:text").attr("text-anchor", "middle").attr("dy", ".3em").attr("font-size", "1em").text(function(d) {
        return d.name.substring(0, d.r / 2.5);
      });
    };
    Timeliner.prototype.circleToGlobalsCoords = function(element) {
      var pt, root, transform;
      root = this.vis[0][0];
      pt = root.createSVGPoint();
      pt.x = element.cx.baseVal.value;
      pt.y = element.cy.baseVal.value;
      transform = element.getTransformToElement(root);
      return pt = pt.matrixTransform(transform);
    };
    return Timeliner;
  })();
  window.Timeliner = Timeliner;
}).call(this);