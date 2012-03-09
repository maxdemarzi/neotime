class Timeliner

  constructor: ->
    console.info("Ignition")

  plot: (cases, parties) ->
    w = 1200 
    h = 900

    @highlightColor = "#fff"
    @partyUnselectedColor = "#dcd6cd"
    @caseUnselectedColor = "#aaa"

    @vis = d3.select("#chart").insert("svg")
      .attr("width", w)
      .attr("height", h)
      .attr("class", "timeline_container")

    # TODO: srsly, find a better way
    window.vis = @vis

    @vis.append("text")
      .text("Point to a case to see its connections")
      .attr("x", 0)
      .attr("y", 2)
      .attr("dy", ".71em")
      .attr("id", "caseName")

    @plotCases(cases)
    @plotParties(parties)


  addPartyConnections: (d,i, element) ->
    d3.selectAll("line.connection").remove()
    d3.select("#caseName").text(d.name)
    d3.select(element)
      .transition()
      .style("fill", @highlightColor)      

    self = @

    partyPt = self.circleToGlobalsCoords(element)

    d3.selectAll("#correspondent_" + d.id).each (eD, eI) ->
      exchangePt = self.circleToGlobalsCoords(this.childNodes[0])
      if eD.incoming
        start = partyPt
        stop = exchangePt
        connectionClass = "connection incoming"
      else
        start = exchangePt
        stop = partyPt
        connectionClass = "connection"

      window.vis.append("svg:line")
        .attr("x1", start.x)
        .attr("y1", start.y)
        .attr("x2", start.x)
        .attr("y2", start.y)
        .style("stroke-width", 0.4)
        .attr("class", connectionClass)
        .transition()
          .duration(1500)
          .attr("x2", stop.x)
          .attr("y2", stop.y)


  removePartyConnections: (d,i, element) ->
    d3.select(element)
      .transition()
      .style("fill", @partyUnselectedColor)      


  addExchangeConnections: (d, i, element) ->
    d3.selectAll("line.connection").remove()
    d3.select("#caseName").text(d.title)
    d3.select(element)
      .transition()
      .style("fill", @highlightColor)      

    self = @
    d3.select(element).selectAll("g.exchange").each (d,i) ->
      exchangePt = self.circleToGlobalsCoords(this.childNodes[0])
      
      d3.select("#party_" + d.sender_or_recipent).each (dp,i) ->
        party = d3.select(this).select("circle")
        partyPt = self.circleToGlobalsCoords(party[0][0])

        party
          .transition()
          .style("fill", self.highlightColor)

        party
          .attr("class", "selected")

        if d.incoming
          start = partyPt
          stop = exchangePt
          connectionClass = "connection incoming"
        else
          start = exchangePt
          stop = partyPt
          connectionClass = "connection"

        window.vis.append("svg:line")
          .attr("x1", start.x)
          .attr("y1", start.y)
          .attr("x2", start.x)
          .attr("y2", start.y)
          .style("stroke-width", 0.4)
          .attr("class", connectionClass)
          .transition()
            .duration(1500)
            .attr("x2", stop.x)
            .attr("y2", stop.y)

  removeExchangeConnections: (d, i, element) ->
    d3.select(element)
      .transition()
      .style("fill", @caseUnselectedColor)      

    d3.selectAll("line.connection")
      .transition()
      .attr("opacity", 0)
      .remove()

    d3.selectAll("circle.selected")
      .attr("class", "")
      .transition()
      .style("fill", "#dcd6cd")

  plotCases: (cases) ->
    m = [0, 00, 00, 40]

    w = 1100 - m[1] - m[3]
    h = 900 - m[0] - m[2]
    parse = d3.time.format("%Y-%m-%d").parse
    e = cases.length

    # Scales. Note the inverted domain for the y-scale: bigger is up!
    x = d3.time.scale().range([0, w])
    y = d3.scale.linear(0,cases.length).range([0, h])

    # Axes
    xAxis = d3.svg.axis().scale(x).tickSize(4).tickSubdivide(true).orient("top")

    # Parse values
    cases.forEach (d) ->  
      d.initiated_at = parse(d.initiated_at)
      d.last_correspondance_at = parse(d.last_correspondance_at)

    # Compute the minimum and maximum date, and the maximum price.
    x.domain([cases[0].initiated_at, d3.max( cases, (d) -> d.last_correspondance_at)])
    y.domain([0, e])

    barHeight = y(cases.length)/e*0.7

    timelines = @vis.append("svg:g")
      .attr("transform", "translate(" + m[2] + "," + m[3] + ")")
      .attr("class", "case_canvas")

    self = @

    cases = timelines.selectAll("g.case")
        .data(cases)
      .enter().append("svg:g")
        .attr("class", "case")
        .attr("transform", (d,i) -> "translate(0," + y(i+1) + ")")
        .on("mouseover", (d,i) -> self.addExchangeConnections(d, i, this))
        .on("mouseout", (d,i) -> self.removeExchangeConnections(d, i, this))
        .attr("fill", "#aaa")

    cases.append("svg:rect")
        .attr("width", (d,i) -> 0)
        .attr("x", (d) -> x(d.initiated_at))
        .attr("height", barHeight)
      .transition()
        .attr("width", (d,i) ->  x(d.last_correspondance_at) - x(d.initiated_at))
        .delay((d, i) -> i * 10)

    exchanges = cases.selectAll("g.exchanges")
        .data( (d) -> d.exchanges )
      .enter().append("svg:g")
        .attr("class", "exchange")
        .attr("id", (d) -> "correspondent_" + d.sender_or_recipent)
        .attr("transform", (d) -> "0,0)")

    exchanges.append("svg:circle")
        .attr("r", 1.5)
        .attr("cx", (d,i) -> x(parse(d.journal_date)))
        .attr("cy", barHeight/2)

    # exchanges.append("svg:line")
    #   .attr("x1", (d,i) -> Math.floor(x(parse(d.journal_date))) + 0.5)
    #   .attr("y1", 0.5)
    #   .attr("x2", (d,i) -> Math.floor(x(parse(d.journal_date))) + 0.5)
    #   .attr("y2", barHeight - 1)
    #   .style("stroke-width", 1)
    #   .style("stroke", "#000")
    #   .style("opacity", "1")
    #   .attr("shape-rendering", "crispEdges")

    # Add the x-axis.
    timelines.append("svg:g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + 0 + ")")
      .call(xAxis)

  plotParties: (parties) ->
    w = 600
    h = 600
    hOffset = 280
    wOffset = 00

    format = d3.format(",d")
    color = d3.interpolateRgb("#eee", @highlightColor)
    bubble = d3.layout.pack()
      .sort(null)
      .size([w, h])

    parties = {children: parties}

    bubbles = @vis.append("svg:g")
      .attr("transform", "translate(" + wOffset + "," + hOffset + ")")

    node = bubbles.selectAll("g.node")
      .data(bubble.nodes(parties).filter( (d) -> !d.children))
      .enter().append("svg:g")
        .attr("class", "party")
        .attr("id", (d) -> "party_" + d.id)
        .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")" )

    node.append("svg:title")
      .text((d) -> d.name + ": " + format(d.value))

    self = @
    node.append("svg:circle")
      .attr("r", (d) -> 0 )
      .style("fill", @partyUnselectedColor)
      .on("mouseover", (d,i) -> self.addPartyConnections(d, i, this))
      .on("mouseout", (d,i) -> self.removePartyConnections(d, i, this))
      .transition()
        .duration(100)
        .attr("r", (d) -> d.r * 0.9 )
        .delay((d, i) -> i * 3)

    node.append("svg:text")
      .attr("text-anchor", "middle")
      .attr("dy", ".3em")
      .attr("font-size", ".8em")
      .text( (d) -> d.name.substring(0, d.r / 2.5))

  circleToGlobalsCoords: (element) ->
    root = @vis[0][0]
    pt = root.createSVGPoint()
    pt.x = element.cx.baseVal.value
    pt.y = element.cy.baseVal.value
    transform = element.getTransformToElement(root)
    pt = pt.matrixTransform(transform)


window.Timeliner = Timeliner