#!/usr/bin/env cwl-runner
cwlVersion: v1.2
class: CommandLineTool

label: "Get Speed"
doc: "Computes speed = distance / time. Wraps the get_speed Python function."

baseCommand: [python3, get_speed.py]

inputs:
  distance:
    type: float
    label: "Distance (m)"
    doc: "Distance in meters"
    inputBinding:
      prefix: --distance
      position: 1
  time:
    type: float
    label: "Time (s)"
    doc: "Time in seconds"
    inputBinding:
      prefix: --time
      position: 2

outputs:
  speed:
    type: float
    label: "Speed (m/s)"
    doc: "Speed in meters per second"
    outputBinding:
      glob: speed_output.json
