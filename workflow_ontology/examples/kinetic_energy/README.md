# Kinetic Energy — CWL Workflow Example

This example shows how to convert a CWL workflow into an OWL/Turtle knowledge graph instance using the **Exa-AToW Workflow** ontologies, and how to visualise it interactively in a browser.

It is based on the canonical example from [**semantikon**](https://github.com/pyiron/semantikon), a Python library for annotating functions with semantic metadata (units, ontology URIs). The original workflow uses `semantikon`'s `u()` decorator to attach RDF annotations to function parameters — here we convert it to CWL and instantiate it as an OWL knowledge graph using the Exa-AToW Workflow ontologies.

The workflow modelled:

```python
from semantikon import u
from rdflib import Namespace
EX = Namespace("http://example.org/")

def get_speed(
    distance: u(float, uri=EX.distance, units="meter"),
    time:     u(float, uri=EX.time,     units="second"),
) -> u(float, uri=EX.speed, units="meter/second"):
    return distance / time

def get_kinetic_energy(
    mass:     u(float, units="kilogram",     uri=EX.Mass),
    velocity: u(float, units="meter/second", uri=EX.Velocity),
) -> u(float, units="joule", uri=EX.KineticEnergy):
    return 0.5 * mass * velocity**2

def my_kinetic_energy_workflow(distance, time, mass):
    speed          = get_speed(distance, time)       # step 1
    kinetic_energy = get_kinetic_energy(mass, speed) # step 2
    return kinetic_energy
```

> The semantic annotations (`uri=`, `units=`) are not yet reflected in the CWL/OWL conversion — this is planned for a future version.

---

## Folder contents

```
examples/kinetic_energy/
├── kinetic_energy_workflow.cwl      ← main CWL Workflow (entry point)
├── get_speed.cwl                    ← CWL tool: speed = distance / time
├── get_kinetic_energy.cwl           ← CWL tool: KE = 0.5 · mass · velocity²
├── kinetic_energy_instance.ttl      ← pre-generated OWL instance (ready to view)
└── README.md                        ← this file
```

The conversion script and viewer live at the repo root:

```
├── tools/cwl_to_ttl.py              ← CWL → Turtle converter
└── viewer/onto-viewer.html          ← browser-based ontology visualiser
```

---

## Prerequisites

- Python 3.10+
- A modern browser (Firefox, Chrome)

Install Python dependencies:

```bash
pip install rdflib pyyaml
```

---

## Step 1 — Generate the Turtle instance

A pre-generated `kinetic_energy_instance.ttl` is already included — you can skip straight to [Step 2](#step-2--visualise-with-onto-viewerhtml) if you just want to visualise it.

To regenerate it from the CWL files, run from this folder:

```bash
python ../../tools/cwl_to_ttl.py kinetic_energy_workflow.cwl \
    -o kinetic_energy_instance.ttl \
    --base "http://example.org/kinetic_energy#"
```

Expected output:

```
Reading  : kinetic_energy_workflow.cwl
Base NS  : http://example.org/kinetic_energy#
Output   : kinetic_energy_instance.ttl
Done — 152 triples written to kinetic_energy_instance.ttl
```

### CWL files

The three CWL files implement the workflow as `python3 -c` inline scripts. Each tool captures its result via `stdout` and reads it back as a `float` using `InlineJavascriptRequirement`.

**`get_speed.cwl`** — computes `speed = distance / time`:

```yaml
cwlVersion: v1.2
class: CommandLineTool

requirements:
  InlineJavascriptRequirement: {}

baseCommand: python3

arguments:
  - prefix: -c
    valueFrom: |
      import sys
      distance = float(sys.argv[1])
      time = float(sys.argv[2])
      speed = distance / time
      print(speed)

inputs:
  distance: { type: float, inputBinding: { position: 1 } }
  time:     { type: float, inputBinding: { position: 2 } }

outputs:
  speed:
    type: float
    outputBinding:
      glob: speed_output.txt
      loadContents: true
      outputEval: $(parseFloat(self[0].contents.trim()))

stdout: speed_output.txt
```

**`get_kinetic_energy.cwl`** — computes `KE = 0.5 · mass · velocity²`:

```yaml
cwlVersion: v1.2
class: CommandLineTool

requirements:
  InlineJavascriptRequirement: {}

baseCommand: python3

arguments:
  - prefix: -c
    valueFrom: |
      import sys
      mass = float(sys.argv[1])
      velocity = float(sys.argv[2])
      kinetic_energy = 0.5 * mass * velocity ** 2
      print(kinetic_energy)

inputs:
  mass:     { type: float, inputBinding: { position: 1 } }
  velocity: { type: float, inputBinding: { position: 2 } }

outputs:
  kinetic_energy:
    type: float
    outputBinding:
      glob: kinetic_energy_output.txt
      loadContents: true
      outputEval: $(parseFloat(self[0].contents.trim()))

stdout: kinetic_energy_output.txt
```

**`my_kinetic_energy_workflow.cwl`** — wires the two steps together, passing `get_speed/speed` as `velocity` into `get_kinetic_energy`:

```yaml
cwlVersion: v1.2
class: Workflow

inputs:
  distance: { type: float }
  time:     { type: float }
  mass:     { type: float }

outputs:
  kinetic_energy:
    type: float
    outputSource: get_kinetic_energy/kinetic_energy

steps:
  get_speed:
    run: get_speed.cwl
    in:
      distance: distance
      time: time
    out: [speed]

  get_kinetic_energy:
    run: get_kinetic_energy.cwl
    in:
      mass:     mass
      velocity: get_speed/speed
    out: [kinetic_energy]
```

### Running the workflow

Create an `inputs.yml` file:

```yaml
distance: 100.0
time: 9.58
mass: 70.0
```

Then run:

```bash
mkdir -p results && cwltool kinetic_energy_workflow.cwl inputs.yml > results/output.json
```

Validate the CWL workflow without executing:

```bash
cwltool --validate kinetic_energy_workflow.cwl
```

### What the converter generates

| Individual | Type | Description |
|---|---|---|
| `inst:wf_Kinetic_Energy_Workflow` | `CWLWorkflow` | The workflow itself |
| `inst:step_get_speed` | `CWLWorkflowStep` | Step 1 |
| `inst:step_get_kinetic_energy` | `CWLWorkflowStep` | Step 2 |
| `inst:tool_get_speed` | `CWLCommandLineTool` | Tool behind step 1 |
| `inst:tool_get_kinetic_energy` | `CWLCommandLineTool` | Tool behind step 2 |
| `inst:wf_input_distance/time/mass` | `InputParameter` | Workflow-level inputs |
| `inst:wf_output_kinetic_energy` | `OutputParameter` | Workflow-level output |
| `inst:step_*_in_*` / `inst:step_*_out_*` | `Input/OutputParameter` | Step-level parameters |

Key relationships asserted:

```
inst:wf_Kinetic_Energy_Workflow
    ├── exato-wf:hasStep → inst:step_get_speed
    │       ├── exato-wf:hasInputParameter  → inst:step_get_speed_in_distance
    │       │                               → inst:step_get_speed_in_time
    │       ├── exato-wf:hasOutputParameter → inst:step_get_speed_out_speed
    │       └── exato-wf-cwl:runs          → inst:tool_get_speed
    │
    └── exato-wf:hasStep → inst:step_get_kinetic_energy
            ├── exato-wf:dependsOn          → inst:step_get_speed   ← execution order
            ├── exato-wf:hasInputParameter  → inst:step_get_kinetic_energy_in_mass
            │                               → inst:step_get_kinetic_energy_in_velocity
            ├── exato-wf:hasOutputParameter → inst:step_get_kinetic_energy_out_kinetic_energy
            └── exato-wf-cwl:runs          → inst:tool_get_kinetic_energy

Data link: inst:step_get_speed_out_speed
               → exato-wf:connectsTo → inst:step_get_kinetic_energy_in_velocity
```

`exato-wf:dependsOn` is inferred automatically from the CWL `source:` wiring: because `get_kinetic_energy` takes `get_speed/speed` as input, the script asserts that it depends on `get_speed`.

---

## Step 2 — Visualise with onto-viewer.html

Open `../../viewer/onto-viewer.html` in your browser or from the web: 

[https://cnherrera.github.io/Exa-AToW_onto/tools/onto_visualization/onto-viewer.html](https://cnherrera.github.io/Exa-AToW_onto/tools/onto_visualization/onto-viewer.html)



### Upload instance from the web (URL)

Write the URL of the instance of the workflow in "TTL URL":  

https://cnherrera.github.io/Exa-AToW_onto/workflow_ontology/examples/kinetic_energ/kinetic_energy_instance.ttl


### Or load the instance form local machine

You can load a TTL file from your local machine:

1. Click the **folder icon** in the top-left toolbar to upload a local file, or click the **link icon** to enter a URL.
2. Select `kinetic_energy_instance.ttl` from this folder.
3. The graph renders automatically.

---

### Navigation

| Action | How |
|---|---|
| Pan | Click and drag on the canvas |
| Zoom | Scroll wheel |
| Inspect a node or edge | Click on it — details appear in the right panel |
| Fit to screen | Click **⊞ Fit** in the toolbar |
| Reset view | Click **↺ Reset** in the toolbar |

---

### Toolbar toggles

| Toggle | Effect |
|---|---|
| **TBox** | Show/hide ontology classes and properties |
| **Instances** | Show/hide individual instances (ABox) |
| **Edge labels** | Show/hide predicate names on edges |
| **Layout** | Switch between graph layout algorithms (e.g. dagre, cose) |

---

### Node details panel

Click any node to open its detail panel on the right:

- **Classes** — URI, comment, superclasses, subclasses, instances
- **Instances** — URI, type, all outgoing properties and their values
- **Imported concepts** — URI, comment, superclasses, subclasses, and which instances use them (see below)

Click any pill in the panel to navigate directly to that node.

---

### Viewing imported ontology concepts

The instance file uses classes and properties from external ontologies (e.g. `exato-wf:WorkflowStep`, `exato-wf-cwl:CWLWorkflow`). These are not embedded in the TTL to keep it readable, but you can load them on demand:

1. Click **🔗 Imported Concepts** in the toolbar.
2. The viewer detects which external namespaces are referenced by your instances and shows them as **clickable chips** — click one to add it as a URL to load.
3. Enter the full URL of the ontology TTL for each namespace (you can add multiple).
4. Click **Load & Show**.

The viewer fetches each ontology, extracts only the classes and properties actually used in your instances, resolves their ancestor chain (`rdfs:subClassOf`), and injects them into the graph as **dashed round-rectangle nodes** coloured by branch. Edges labelled `type` connect each instance to its external class.

To remove imported concepts from the graph, reopen the modal and click **Clear**.

---

## Using cwl_to_ttl.py with your own CWL workflow

The script is general — it works with any CWL Workflow file. Place your files in a folder following this layout:

```
my_workflow/
├── my_workflow.cwl        ← entry point (class: Workflow)
├── tool_a.cwl             ← referenced by run: tool_a.cwl
└── tool_b.cwl
```

Then run:

```bash
python ../../tools/cwl_to_ttl.py my_workflow.cwl \
    -o my_workflow_instance.ttl \
    --base "http://example.org/my_workflow#"
```

| Flag | Default | Description |
|---|---|---|
| `cwl_file` | *(required)* | Path to the CWL Workflow file |
| `-o`, `--output` | `<cwl_stem>_instance.ttl` | Output Turtle file path |
| `--base` | `http://example.org/<cwl_stem>#` | Base namespace URI for all generated instances |

---

## Troubleshooting

**Syntax error on TTL load in the viewer**
Validate the file first:
```bash
python3 -c "from rdflib import Graph; g = Graph(); g.parse('kinetic_energy_instance.ttl')"
```

**Steps appear but no edges between them**
Check that your CWL steps use `source:` fields to wire inputs — these are what the script uses to infer `dependsOn` and `connectsTo` links.