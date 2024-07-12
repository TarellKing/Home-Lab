<mxfile host="app.diagrams.net" modified="2024-07-12T22:16:23.278Z" agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36" etag="sudO3_aj6iPmNNpUEdQ1" border="50" scale="3" compressed="false" locked="false" version="24.6.5" type="github">
  <diagram name="Blank" id="YmL12bMKpDGza6XwsDPr">
    <mxGraphModel dx="2234" dy="1172" grid="0" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="0" pageScale="1" pageWidth="827" pageHeight="1169" background="none" math="1" shadow="0">
      <root>
        <mxCell id="X5NqExCQtvZxIxQ7pmgY-0" />
        <mxCell id="1" parent="X5NqExCQtvZxIxQ7pmgY-0" />
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-3" value="Internet" style="ellipse;shape=cloud;whiteSpace=wrap;html=1;" parent="1" vertex="1">
          <mxGeometry x="-800" y="66" width="120" height="80" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-4" value="" style="endArrow=none;html=1;rounded=0;" parent="1" source="XQuCqsXmrW_UCGvWZyHM-2" target="XQuCqsXmrW_UCGvWZyHM-3" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="-409" y="542" as="sourcePoint" />
            <mxPoint x="-359" y="492" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-9" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;" parent="1" source="XQuCqsXmrW_UCGvWZyHM-2" target="XQuCqsXmrW_UCGvWZyHM-8" edge="1">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-19" value="" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;" parent="1" source="XQuCqsXmrW_UCGvWZyHM-2" target="8XFWg_bhrVFhV3nUEREt-1" edge="1">
          <mxGeometry relative="1" as="geometry">
            <mxPoint x="-432.9000000000001" y="105" as="targetPoint" />
          </mxGeometry>
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-2" value="" style="image;html=1;image=img/lib/clip_art/computers/Server_Tower_128x128.png" parent="1" vertex="1">
          <mxGeometry x="-473" y="260" width="80" height="80" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-8" value="NIC&lt;div&gt;(Internet)&lt;/div&gt;&lt;div&gt;DHCP Will get addressing from home router&lt;/div&gt;" style="rounded=1;whiteSpace=wrap;html=1;verticalAlign=top;labelBackgroundColor=default;" parent="1" vertex="1">
          <mxGeometry x="-334" y="315.5" width="171" height="73" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-12" value="NIC&lt;div&gt;(Internal)&lt;/div&gt;&lt;div&gt;IP:&amp;nbsp; 192.168.1.20&lt;/div&gt;&lt;div&gt;Mask: 255.255.255.0&lt;/div&gt;&lt;div&gt;Gateway: 192.168.1.1&lt;/div&gt;&lt;div&gt;DNS: 192.168.1.10&lt;/div&gt;" style="rounded=1;whiteSpace=wrap;html=1;verticalAlign=top;labelBackgroundColor=default;" parent="1" vertex="1">
          <mxGeometry x="-680" y="300" width="171" height="104" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-23" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.65;entryDx=0;entryDy=0;entryPerimeter=0;" parent="1" source="XQuCqsXmrW_UCGvWZyHM-12" target="XQuCqsXmrW_UCGvWZyHM-2" edge="1">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-27" value="" style="fontColor=#0066CC;verticalAlign=top;verticalLabelPosition=bottom;labelPosition=center;align=center;html=1;outlineConnect=0;fillColor=#CCCCCC;strokeColor=#6881B3;gradientColor=none;gradientDirection=north;strokeWidth=2;shape=mxgraph.networks.pc;" parent="1" vertex="1">
          <mxGeometry x="-51" y="83" width="110" height="77" as="geometry" />
        </mxCell>
        <mxCell id="XQuCqsXmrW_UCGvWZyHM-28" value="" style="endArrow=none;html=1;rounded=0;exitX=1;exitY=0.25;exitDx=0;exitDy=0;" parent="1" source="XQuCqsXmrW_UCGvWZyHM-2" target="XQuCqsXmrW_UCGvWZyHM-27" edge="1">
          <mxGeometry width="50" height="50" relative="1" as="geometry">
            <mxPoint x="-398" y="300" as="sourcePoint" />
            <mxPoint x="-348" y="250" as="targetPoint" />
            <Array as="points" />
          </mxGeometry>
        </mxCell>
        <mxCell id="8XFWg_bhrVFhV3nUEREt-1" value="&lt;b&gt;DC Server&lt;/b&gt;" style="swimlane;fontStyle=0;childLayout=stackLayout;horizontal=1;startSize=30;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=1;marginBottom=0;whiteSpace=wrap;html=1;strokeWidth=2;" vertex="1" parent="1">
          <mxGeometry x="-604.83" y="-207" width="343.66" height="220" as="geometry">
            <mxRectangle x="-604.83" y="-207" width="91" height="30" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="8XFWg_bhrVFhV3nUEREt-2" value="&lt;b&gt;Domain / AD DS&amp;nbsp;&lt;/b&gt;&lt;div&gt;FQDN: TarellsDomain.com&lt;/div&gt;&lt;div&gt;&lt;br&gt;&lt;/div&gt;" style="text;strokeColor=default;fillColor=none;align=center;verticalAlign=middle;spacingLeft=4;spacingRight=4;overflow=hidden;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;rotatable=0;whiteSpace=wrap;html=1;" vertex="1" parent="8XFWg_bhrVFhV3nUEREt-1">
          <mxGeometry y="30" width="343.66" height="47" as="geometry" />
        </mxCell>
        <mxCell id="8XFWg_bhrVFhV3nUEREt-3" value="&lt;b&gt;RAS/NAT&lt;/b&gt;&lt;div&gt;Outside: Internet&lt;/div&gt;&lt;div&gt;Inside: Internal&amp;nbsp;&amp;nbsp;&lt;/div&gt;" style="text;strokeColor=default;fillColor=none;align=center;verticalAlign=middle;spacingLeft=4;spacingRight=4;overflow=hidden;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;rotatable=0;whiteSpace=wrap;html=1;strokeWidth=2;" vertex="1" parent="8XFWg_bhrVFhV3nUEREt-1">
          <mxGeometry y="77" width="343.66" height="56" as="geometry" />
        </mxCell>
        <mxCell id="8XFWg_bhrVFhV3nUEREt-4" value="&lt;b&gt;DHCP Scope&lt;/b&gt;&lt;div&gt;Range: 192.168.1.100 - 150&lt;/div&gt;&lt;div&gt;Mask: 255.255.255.0&lt;/div&gt;&lt;div&gt;Gateway: 192.168.1.1&lt;/div&gt;&lt;div&gt;DNS: 192.168.1.10&lt;/div&gt;&lt;div&gt;&lt;br&gt;&lt;/div&gt;" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;spacingLeft=4;spacingRight=4;overflow=hidden;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;rotatable=0;whiteSpace=wrap;html=1;strokeWidth=3;" vertex="1" parent="8XFWg_bhrVFhV3nUEREt-1">
          <mxGeometry y="133" width="343.66" height="87" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
