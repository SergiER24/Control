// Node-oriented editable pro deck builder.
// Run this after editing SLIDES, SOURCES, and layout functions.
// The init script installs a sibling node_modules/@oai/artifact-tool package link
// and package.json with type=module for shell-run eval builders. Run with the
// Node executable from Codex workspace dependencies or the platform-appropriate
// command emitted by the init script.
// Do not use pnpm exec from the repo root or any Node binary whose module
// lookup cannot resolve the builder's sibling node_modules/@oai/artifact-tool.

const fs = await import("node:fs/promises");
const path = await import("node:path");
const { Presentation, PresentationFile } = await import("@oai/artifact-tool");

const W = 1280;
const H = 720;

const DECK_ID = "plataforma-antivibratoria-control";
const OUT_DIR = "/Users/sergioe.ropero/Documents/2026/Control/presentacion_control/outputs";
const REF_DIR = "/Users/sergioe.ropero/Documents/2026/Control/presentacion_control/reference";
const SCRATCH_DIR = path.resolve(process.env.PPTX_SCRATCH_DIR || path.join("tmp", "slides", DECK_ID));
const PREVIEW_DIR = path.join(SCRATCH_DIR, "preview");
const VERIFICATION_DIR = path.join(SCRATCH_DIR, "verification");
const INSPECT_PATH = path.join(SCRATCH_DIR, "inspect.ndjson");
const MAX_RENDER_VERIFY_LOOPS = 3;

const INK = "#101214";
const GRAPHITE = "#30363A";
const MUTED = "#687076";
const PAPER = "#F7F4ED";
const PAPER_96 = "#F7F4EDF5";
const WHITE = "#FFFFFF";
const ACCENT = "#27C47D";
const ACCENT_DARK = "#116B49";
const GOLD = "#D7A83D";
const CORAL = "#E86F5B";
const TRANSPARENT = "#00000000";

const TITLE_FACE = "Caladea";
const BODY_FACE = "Lato";
const MONO_FACE = "Aptos Mono";
const MATH_FACE = "Cambria Math";

const FALLBACK_PLATE_DATA_URL =
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=";

const SOURCES = {
  primary: "Actividad 2 de Control, desarrollo propio del modelo y simulaciones del proyecto.",
  course: "Notas de clase de Modelado, Estabilidad, Sintonizacion e IMC-PID.",
};

const CITATIONS = {
  enunciado: "Enunciado Actividad 2, Curso de Control, 2026.",
  imc: "N. Quijano, IMC y PID, notas de clase.",
  estabilidad1: "N. Quijano, Estabilidad 1, notas de clase.",
  estabilidad2: "N. Quijano, Estabilidad en LTI, notas de clase.",
  sintonizacion2: "N. Quijano, Controladores PID: Sintonizacion, notas de clase.",
  controlpid: "Control PID, material de clase y referencias introductorias.",
  propio: "Desarrollo propio del grupo a partir del modelado fisico del sistema.",
};

const SLIDES = [
  {
    type: "cover",
    kicker: "ACTIVIDAD 2",
    title: "Plataforma Antivibratoria Activa para un Sensor de Ultrasonido",
    subtitle:
      "Proyecto de control orientado al rechazo de perturbaciones en un montaje de laboratorio para deteccion de plagas en papas.",
    moment: "Objetivo central: r(t)=0",
    notes: "Presentar el problema, el contexto experimental y la idea fuerza del proyecto.",
    sources: ["primary", "course"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "agenda",
    kicker: "CONTENIDO",
    title: "Ruta de la sustentacion",
    subtitle: "La presentacion se divide en un bloque principal de exposicion y un bloque final de respaldo tecnico.",
    leftTitle: "Bloque principal",
    leftBullets: [
      "Contexto de aplicacion y objetivo de control.",
      "Modelo realista, modelo fisico y planta nominal.",
      "Estabilidad, comparacion en lazo abierto y reduccion.",
      "Sintonia IMC-PID e implementacion en Simulink.",
      "Resultados en regulacion y seguimiento.",
    ],
    rightTitle: "Bloque de respaldo",
    rightBullets: [
      "Tabla de metricas estimadas.",
      "Conclusiones del proyecto.",
      "Bono de visualizacion 3D.",
      "Uso de IA y apoyo computacional.",
      "Respaldo tecnico con formulas clave.",
    ],
    note: "El recorrido principal llega hasta resultados; el bloque final queda para preguntas del profesor o profundizacion tecnica.",
    notes: "Usar este slide para orientar la exposicion antes de entrar al contexto y al modelado.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "cards",
    kicker: "CONTEXTO",
    title: "Problema y contexto de aplicacion",
    subtitle:
      "El montaje de laboratorio usa un sensor de ultrasonido para detectar plagas en papas y la vibracion de la mesa altera la medicion.",
    cards: [
      [
        "Aplicacion",
        "El proyecto se motiva por una prueba de laboratorio donde la variable observada depende de la distancia medida por un sensor de ultrasonido.",
      ],
      [
        "Problema fisico",
        "Si la mesa vibra, cambia la posicion relativa del sensor y aparecen errores de lectura que no corresponden al estado real del objeto medido.",
      ],
      [
        "Necesidad de control",
        "La plataforma debe permanecer practicamente inmovil para conservar la calidad de medicion aun cuando la base reciba perturbaciones externas.",
      ],
    ],
    notes: "Enfatizar que la motivacion real es proteger la medicion del sensor frente a vibraciones de la mesa.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "metrics",
    kicker: "OBJETIVO DE CONTROL",
    title: "Objetivo de control y por que la planta es de tercer orden",
    subtitle:
      "El caso principal es regulacion con r(t)=0 y la planta nominal tiene tres estados: posicion relativa, velocidad y corriente del actuador.",
    metrics: [
      ["Orden 3", "Dos estados mecanicos + uno electrico", "q, q̇, i"],
      ["r(t)=0", "Setpoint fijo en regulacion", "Caso principal"],
      ["u(t)", "Voltaje aplicado al actuador", "Variable manipulada"],
    ],
    summary: [
      "q es la posicion relativa entre plataforma y base.",
      "q̇ es la velocidad relativa de la plataforma.",
      "i es la corriente interna del actuador.",
      "Por eso el orden del sistema es 2 + 1 = 3.",
    ],
    notes:
      "Explicar desde el inicio que la planta es de tercer orden porque combina posicion, velocidad y corriente del actuador.",
    sources: ["primary", "course"],
    citations: ["estabilidad1", "propio"],
  },
  {
    type: "model",
    kicker: "MODELO REALISTA",
    title: "Modelo realista del sistema",
    subtitle: "Se representa la base vibrante, la plataforma con el sensor, el resorte, el amortiguador y el actuador.",
    bullets: [
      "Base o mesa del laboratorio sometida a perturbaciones externas.",
      "Plataforma superior donde se monta el sensor de ultrasonido.",
      "Resorte y amortiguador viscoso entre base y plataforma.",
      "Actuador electromecanico para aplicar fuerza correctiva.",
      "Modelo realista en Simulink/Simscape con espacio para saturacion y efectos adicionales.",
    ],
    placeholderTitle: "Captura del modelo Simulink / Simscape",
    placeholderText:
      "Inserta aqui el diagrama final del modelo realista con base, plataforma, actuador y elementos mecanicos.",
    note: "Este slide debe mostrar el montaje realista que luego se compara con el modelo nominal.",
    notes: "Presentar el diagrama del sistema realista y señalar donde entra la perturbacion de base.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "equations",
    kicker: "MODELO FISICO",
    title: "Modelo fisico completo",
    subtitle: "El sistema se plantea con una ecuacion mecanica y un actuador electromecanico lineal acoplado.",
    panels: [
      {
        title: "Ecuacion mecanica",
        formula: "m q̈ + c q̇ + k q = Fₐ - m z̈",
        lines: [
          "La masa, el resorte y el amortiguamiento reaccionan frente a la fuerza activa y frente a la aceleracion de la base.",
        ],
      },
      {
        title: "Modelo del actuador",
        formula: "Fₐ = Kf i\nu = L i̇ + R i + Kₑ q̇",
        lines: [
          "Se toma un actuador electromagnetico lineal donde la fuerza es proporcional a la corriente.",
          "La ecuacion de voltaje sale del balance electrico en la bobina e incluye la fuerza contraelectromotriz Kₑ q̇.",
        ],
      },
    ],
    footerTitle: "Interpretacion fisica",
    footerLines: [
      "Sustituyendo Fₐ = Kf i en la ecuacion mecanica se obtiene el modelo acoplado completo del sistema.",
      "La corriente i(t) es el tercer estado del modelo y por eso la planta nominal resulta de tercer orden.",
    ],
    notes: "Explicar de donde sale cada ecuacion y por que el actuador introduce un estado adicional.",
    sources: ["primary", "course"],
    citations: ["controlpid", "estabilidad1", "propio"],
  },
  {
    type: "plant",
    kicker: "PLANTA NOMINAL",
    title: "Planta nominal y funcion de transferencia",
    subtitle:
      "Para analisis se toma z(t)=0 y se obtiene una planta nominal con estados q, q̇ e i.",
    leftTitle: "Estados y espacio de estados",
    leftFormula:
      "x = [ q   q̇   i ]ᵀ\nẋ = A x + B u\ny = C x + D u",
    leftLines: [
      "La entrada nominal es el voltaje u(t).",
      "La salida puede tomarse como la posicion de la plataforma alrededor del equilibrio.",
      "Dos estados son mecanicos y uno es electrico.",
    ],
    rightTitle: "Funcion de transferencia nominal",
    rightFormula:
      "G(s) = C (sI - A)⁻¹ B + D\n\nG(s) = Kf / ((L s + R)(m s² + c s + k) + Kf Kₑ s)",
    rightLines: [
      "El denominador cubico confirma que la planta nominal es de tercer orden.",
      "La perturbacion no se incorpora como segunda entrada de la planta nominal.",
    ],
    notes: "Aclarar la diferencia entre modelo fisico completo y planta nominal usada para analisis y control.",
    sources: ["primary", "course"],
    citations: ["estabilidad1", "estabilidad2", "propio"],
  },
  {
    type: "cards",
    kicker: "ESTABILIDAD",
    title: "Estabilidad e interpretacion fisica",
    subtitle: "La estabilidad se estudia con Routh-Hurwitz y luego se interpreta en terminos del montaje real.",
    cards: [
      [
        "Criterio",
        "Para el polinomio a3 s^3 + a2 s^2 + a1 s + a0, se requiere a3 > 0, a2 > 0, a1 > 0, a0 > 0 y ademas a2 a1 > a3 a0.",
      ],
      [
        "Lectura fisica",
        "Los coeficientes positivos reflejan masa, amortiguamiento y rigidez fisicamente realizables, mientras que la condicion cruzada evita modos dominantes inestables.",
      ],
      [
        "Implicacion practica",
        "Que la planta sea estable no garantiza buen aislamiento: tambien debe existir amortiguamiento suficiente para que la vibracion residual no degrade la medicion.",
      ],
    ],
    notes: "Relacionar la estabilidad matematica con la utilidad real del montaje antivibratorio.",
    sources: ["primary", "course"],
    citations: ["estabilidad2", "propio"],
  },
  {
    type: "plots",
    kicker: "COMPARACION EN LAZO ABIERTO",
    title: "Comparacion entre modelo teorico y modelo realista",
    subtitle: "Espacios reservados para contrastar la dinamica en lazo abierto antes del diseno del controlador.",
    plots: [
      ["Lazo abierto teorico con funcion de transferencia", "Inserta aqui la respuesta obtenida con la planta teorica."],
      ["Lazo abierto del modelo realista en Simscape", "Inserta aqui la respuesta del montaje realista en Simscape."],
    ],
    summary: [
      "Comparar rapidez, amortiguamiento y valor final.",
      "Identificar diferencias debidas a saturacion u otros efectos fisicos adicionales.",
      "Usar esta comparacion para justificar el alcance del modelo aproximado.",
    ],
    notes: "Mostrar donde coinciden ambos modelos y donde el modelo realista aporta efectos extra.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "reduction",
    kicker: "REDUCCION DEL MODELO",
    title: "Reduccion para sintonia y respuesta forzada",
    subtitle:
      "La reduccion se usa solo para disenar el controlador, manteniendo la validacion final sobre la planta completa.",
    reducedFormula:
      "ceq = c + Kf Kₑ / R\nL i̇ ≈ 0  ⇒  i ≈ (u - Kₑ q̇) / R\nm q̈ + ceq q̇ + k q = (Kf / R) u + f_p(t)",
    forcedFormula:
      "Gr(s) = 1 / (m s² + c s + k)\nGr(s) = 1 / (s² + 5 s + 100)\nQ(s) = Gr(s) [U(s) + Fp(s)]",
    cards: [
      [
        "Por que se reduce",
        "Se supone que la dinamica electrica es mas rapida que la mecanica y puede aproximarse cuasiestaticamente.",
      ],
      [
        "Que se conserva",
        "Se conserva la dinamica dominante masa-resorte-amortiguador, que gobierna la sintonia del PID.",
      ],
      [
        "Que se pierde",
        "Se pierde el detalle exacto del tercer estado electrico, por lo que la comprobacion final se hace con la planta completa.",
      ],
    ],
    notes: "Explicar que la respuesta forzada sigue importando, porque la aplicacion real es rechazo de perturbaciones.",
    sources: ["primary", "course"],
    citations: ["estabilidad1", "imc", "propio"],
  },
  {
    type: "imc",
    kicker: "DISENO IMC-PID",
    title: "Sintonia IMC-PID sobre el modelo reducido",
    subtitle: "Se emplea el modelo reducido para obtener un PID ideal interpretable y consistente con las notas de clase.",
    topFormula:
      "Gr(s) = 1 / (s² + 5 s + 100)\nF(s) = 1 / (λ s + 1)\nC(s) = Kc (1 + 1 / (Ti s) + Td s)",
    metrics: [
      ["λ = 0.1 s", "Parametro de sintonia IMC", "Se escoge para mantener P = 50"],
      ["Kc = 50", "Ganancia del PID ideal", "Resultado de la sintonia"],
      ["Ti = 0.05 s", "Td = 0.2 s", "Tiempos del PID ideal"],
    ],
    finalLine: "PID ideal final: C(s) = 50 (1 + 1 / (0.05 s) + 0.2 s)",
    notes: "Mostrar el hilo logico completo: modelo reducido, filtro IMC con lambda y parametros finales del PID ideal.",
    sources: ["primary", "course"],
    citations: ["imc", "sintonizacion2", "propio"],
  },
  {
    type: "pidblock",
    kicker: "IMPLEMENTACION DEL PID",
    title: "Equivalencia con el bloque PID de Simulink",
    subtitle:
      "El bloque de Simulink no usa directamente Ki y Kd, sino los tiempos I y D del PID ideal mas un filtro derivativo.",
    idealFormula: "PID ideal\nC(s) = Kc (1 + 1 / (Ti s) + Td s)",
    blockFormula: "Bloque de Simulink\nC(s) = P (1 + 1 / (I s) + D N / (1 + N / s))",
    mappingFormula:
      "Equivalencias\nP = Kc\nI = Ti\nD = Td\nN = 10\n\nImportante: I ≠ Ki y D ≠ Kd",
    finalValues: "Valores usados en Simulink: P = 50, I = 0.05, D = 0.2, N = 10",
    notes: "Aclarar la conversion desde el PID ideal hasta el bloque implementado en Simulink.",
    sources: ["primary", "course"],
    citations: ["imc", "sintonizacion2", "propio"],
  },
  {
    type: "plots",
    kicker: "RESULTADOS PRINCIPALES",
    title: "Lazo cerrado en regulacion con setpoint fijo",
    subtitle: "Caso principal del proyecto: rechazo de perturbaciones con r(t)=0 para mantener estable el sensor.",
    plots: [
      [
        "Lazo cerrado Simscape, regulacion",
        "Inserta aqui la grafica de perturbacion y respuesta con setpoint fijo igual a cero.",
      ],
    ],
    summary: [
      "La perturbacion produce una desviacion transitoria y luego la plataforma retorna al equilibrio.",
      "La respuesta es aceptable para la aplicacion porque la posicion vuelve cerca de cero.",
      "Este es el escenario fisicamente relevante para proteger la medicion del sensor.",
    ],
    notes: "Interpretar la grafica como un problema de regulacion y rechazo de perturbaciones, no de seguimiento.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "plots",
    kicker: "RESULTADOS COMPLEMENTARIOS",
    title: "Seguimiento de referencia de posicion",
    subtitle: "Caso complementario solicitado por el curso para evaluar la respuesta frente a un escalon de referencia.",
    plots: [
      [
        "Lazo cerrado Simscape, seguimiento",
        "Inserta aqui la grafica de seguimiento de posicion frente a un cambio escalon.",
      ],
    ],
    summary: [
      "La respuesta observada es lenta y presenta error estacionario importante.",
      "El controlador funciona mejor como regulador local que como servo de posicion.",
      "Esto no invalida el proyecto, porque la aplicacion real exige principalmente r(t)=0.",
    ],
    notes: "Contrastar explicitamente este resultado con el caso de regulacion para justificar las conclusiones finales.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "table",
    kicker: "RESPALDO 01",
    title: "Tabla de metricas",
    subtitle: "Resumen editable de desempeno para los casos teorico y simulados.",
    support: true,
    tableHeaders: ["Caso", "t_r", "t_s", "M_p", "e_ss"],
    tableRows: [
      ["Lazo abierto teorico", "0.19 s", "1.60 s", "44 %", "0.99"],
      ["Lazo abierto Simscape", "0.20-0.25 s", "1.7-2.0 s", "40-45 %", "0.98-0.99"],
      ["Lazo cerrado Simscape, regulacion", "0.05-0.10 s", "1.0-1.5 s", "0.145", "aprox. 0"],
      ["Lazo cerrado Simscape, seguimiento", "20-25 s", "> 60 s", "0 %", "0.09-0.10"],
    ],
    note:
      "En regulacion, las metricas clasicas son menos naturales; tambien conviene reportar desviacion maxima, tiempo de recuperacion y vibracion residual.",
    notes: "Usar este slide como respaldo metodologico durante preguntas sobre desempeno.",
    sources: ["primary"],
    citations: ["estabilidad2", "propio"],
  },
  {
    type: "conclusions",
    kicker: "RESPALDO 02",
    title: "Conclusiones",
    subtitle: "Resumen corto para cierre oral o respaldo tecnico de la sustentacion.",
    support: true,
    conclusions: [
      "El problema real del proyecto es rechazo de perturbaciones sobre la plataforma del sensor, no seguimiento libre de referencia.",
      "La planta nominal es de tercer orden porque combina una dinamica mecanica de segundo orden con una dinamica electrica de primer orden.",
      "La reduccion a segundo orden fue util para sintetizar el IMC-PID, pero la validacion final se hace sobre la planta completa y Simscape.",
      "El controlador tuvo mejor desempeno en regulacion con r(t)=0 que en seguimiento de posicion, en linea con la aplicacion real.",
    ],
    notes: "Cerrar destacando la coherencia entre el contexto fisico del proyecto y la interpretacion final de los resultados.",
    sources: ["primary", "course"],
    citations: ["enunciado", "imc", "propio"],
  },
  {
    type: "bonus",
    kicker: "RESPALDO 03",
    title: "Bono: visualizacion 3D del montaje",
    subtitle: "Espacio reservado para la vista 3D o una captura del modelo extendido usado como apoyo visual.",
    support: true,
    placeholderTitle: "Visualizacion 3D / frame del bono",
    placeholderText:
      "Inserta aqui una imagen, frame o captura del modelo 3D del sistema para mostrar el montaje de forma mas intuitiva.",
    bullets: [
      "El bono sirve como apoyo visual y no reemplaza el analisis dinamico.",
      "Puede usarse para mostrar la relacion entre base, plataforma y actuador.",
      "Tambien ayuda a explicar el montaje al profesor durante la sustentacion.",
    ],
    notes: "Dejar listo este espacio para insertar la imagen o frame del bono.",
    sources: ["primary"],
    citations: ["enunciado", "propio"],
  },
  {
    type: "gridcards",
    kicker: "RESPALDO 04",
    title: "Uso de IA y apoyo computacional",
    subtitle: "Se declara el uso de herramientas de apoyo sin reemplazar el desarrollo manual del proyecto.",
    support: true,
    cards: [
      [
        "Redaccion y sintesis",
        "Se uso IA para sintetizar y reorganizar el contenido del informe y de la presentacion final.",
      ],
      [
        "Diseno de la presentacion",
        "Se uso IA para apoyar la estructura del deck, la distribucion del contenido y el diseno editable del PPTX.",
      ],
      [
        "Calculos manuales",
        "Los calculos principales del modelado y de la sintonia se desarrollaron a mano y luego se transcribieron al documento.",
      ],
      [
        "Apoyo simbolico",
        "Se uso SymPy en Jupyter Notebook como apoyo algebraico para reducciones y solucion de ecuaciones.",
      ],
      [
        "Apoyo de Codex",
        "Se uso Codex para documentar la implementacion en Simscape y guiar la implementacion del bono 3D.",
      ],
    ],
    notes: "Este slide debe coincidir con la declaracion del informe final sobre uso de IA y herramientas de apoyo.",
    sources: ["primary"],
    citations: ["propio"],
  },
  {
    type: "backup",
    kicker: "RESPALDO 05",
    title: "Respaldo tecnico adicional",
    subtitle: "Formulas clave para preguntas del profesor durante la sustentacion.",
    support: true,
    panels: [
      {
        title: "Modelo completo",
        formula: "m q_ddot + c q_dot + k q = K_f i - m z_ddot\nL i_dot + R i + K_e q_dot = u",
      },
      {
        title: "Planta nominal",
        formula: "G(s) = K_f / [ (L s + R)(m s^2 + c s + k) + K_f K_e s ]",
      },
      {
        title: "PID implementado",
        formula:
          "C(s) = 50 ( 1 + 1 / (0.05 s) + 0.2 s )\nBloque PID: P = 50, I = 0.05, D = 0.2, N = 10",
      },
    ],
    note: "Usar este slide solo como respaldo, no como parte obligatoria del recorrido principal.",
    notes: "Sirve para responder preguntas sobre ecuaciones, orden de la planta y parametros finales del controlador.",
    sources: ["primary", "course"],
    citations: ["estabilidad1", "imc", "propio"],
  },
];

const inspectRecords = [];

async function pathExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function readImageBlob(imagePath) {
  const bytes = await fs.readFile(imagePath);
  if (!bytes.byteLength) {
    throw new Error(`Image file is empty: ${imagePath}`);
  }
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
}

async function normalizeImageConfig(config) {
  if (!config.path) {
    return config;
  }
  const { path: imagePath, ...rest } = config;
  return {
    ...rest,
    blob: await readImageBlob(imagePath),
  };
}

async function ensureDirs() {
  await fs.mkdir(OUT_DIR, { recursive: true });
  const obsoleteFinalArtifacts = [
    "preview",
    "verification",
    "inspect.ndjson",
    ["presentation", "proto.json"].join("_"),
    ["quality", "report.json"].join("_"),
  ];
  for (const obsolete of obsoleteFinalArtifacts) {
    await fs.rm(path.join(OUT_DIR, obsolete), { recursive: true, force: true });
  }
  await fs.rm(PREVIEW_DIR, { recursive: true, force: true });
  await fs.rm(VERIFICATION_DIR, { recursive: true, force: true });
  await fs.rm(INSPECT_PATH, { force: true });
  await fs.mkdir(SCRATCH_DIR, { recursive: true });
  await fs.mkdir(PREVIEW_DIR, { recursive: true });
  await fs.mkdir(VERIFICATION_DIR, { recursive: true });
}

function lineConfig(fill = TRANSPARENT, width = 0) {
  return { style: "solid", fill, width };
}

function recordShape(slideNo, shape, role, shapeType, x, y, w, h) {
  if (!slideNo) return;
  inspectRecords.push({
    kind: "shape",
    slide: slideNo,
    id: shape?.id || `slide-${slideNo}-${role}-${inspectRecords.length + 1}`,
    role,
    shapeType,
    bbox: [x, y, w, h],
  });
}

function addShape(slide, geometry, x, y, w, h, fill = TRANSPARENT, line = TRANSPARENT, lineWidth = 0, meta = {}) {
  const shape = slide.shapes.add({
    geometry,
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: lineConfig(line, lineWidth),
  });
  recordShape(meta.slideNo, shape, meta.role || geometry, geometry, x, y, w, h);
  return shape;
}

function normalizeText(text) {
  if (Array.isArray(text)) {
    return text.map((item) => String(item ?? "")).join("\n");
  }
  return String(text ?? "");
}

function textLineCount(text) {
  const value = normalizeText(text);
  if (!value.trim()) {
    return 0;
  }
  return Math.max(1, value.split(/\n/).length);
}

function requiredTextHeight(text, fontSize, lineHeight = 1.18, minHeight = 8) {
  const lines = textLineCount(text);
  if (lines === 0) {
    return minHeight;
  }
  return Math.max(minHeight, lines * fontSize * lineHeight);
}

function assertTextFits(text, boxHeight, fontSize, role = "text") {
  const required = requiredTextHeight(text, fontSize);
  const tolerance = Math.max(2, fontSize * 0.08);
  if (normalizeText(text).trim() && boxHeight + tolerance < required) {
    throw new Error(
      `${role} text box is too short: height=${boxHeight.toFixed(1)}, required>=${required.toFixed(1)}, ` +
        `lines=${textLineCount(text)}, fontSize=${fontSize}, text=${JSON.stringify(normalizeText(text).slice(0, 90))}`,
    );
  }
}

function wrapText(text, widthChars) {
  const words = normalizeText(text).split(/\s+/).filter(Boolean);
  const lines = [];
  let current = "";
  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > widthChars && current) {
      lines.push(current);
      current = word;
    } else {
      current = next;
    }
  }
  if (current) {
    lines.push(current);
  }
  return lines.join("\n");
}

function recordText(slideNo, shape, role, text, x, y, w, h) {
  const value = normalizeText(text);
  inspectRecords.push({
    kind: "textbox",
    slide: slideNo,
    id: shape?.id || `slide-${slideNo}-${role}-${inspectRecords.length + 1}`,
    role,
    text: value,
    textPreview: value.replace(/\n/g, " | ").slice(0, 180),
    textChars: value.length,
    textLines: textLineCount(value),
    bbox: [x, y, w, h],
  });
}

function recordImage(slideNo, image, role, imagePath, x, y, w, h) {
  inspectRecords.push({
    kind: "image",
    slide: slideNo,
    id: image?.id || `slide-${slideNo}-${role}-${inspectRecords.length + 1}`,
    role,
    path: imagePath,
    bbox: [x, y, w, h],
  });
}

function applyTextStyle(box, text, size, color, bold, face, align, valign, autoFit, listStyle) {
  box.text = text;
  box.text.fontSize = size;
  box.text.color = color;
  box.text.bold = Boolean(bold);
  box.text.alignment = align;
  box.text.verticalAlignment = valign;
  box.text.typeface = face;
  box.text.insets = { left: 0, right: 0, top: 0, bottom: 0 };
  if (autoFit) {
    box.text.autoFit = autoFit;
  }
  if (listStyle) {
    box.text.style = "list";
  }
}

function addText(
  slide,
  slideNo,
  text,
  x,
  y,
  w,
  h,
  {
    size = 22,
    color = INK,
    bold = false,
    face = BODY_FACE,
    align = "left",
    valign = "top",
    fill = TRANSPARENT,
    line = TRANSPARENT,
    lineWidth = 0,
    autoFit = null,
    listStyle = false,
    checkFit = true,
    role = "text",
  } = {},
) {
  if (!checkFit && textLineCount(text) > 1) {
    throw new Error("checkFit=false is only allowed for single-line headers, footers, and captions.");
  }
  if (checkFit) {
    assertTextFits(text, h, size, role);
  }
  const box = addShape(slide, "rect", x, y, w, h, fill, line, lineWidth);
  applyTextStyle(box, text, size, color, bold, face, align, valign, autoFit, listStyle);
  recordText(slideNo, box, role, text, x, y, w, h);
  return box;
}

async function addImage(slide, slideNo, config, position, role, sourcePath = null) {
  const image = slide.images.add(await normalizeImageConfig(config));
  image.position = position;
  recordImage(slideNo, image, role, sourcePath || config.path || config.uri || "inline-data-url", position.left, position.top, position.width, position.height);
  return image;
}

async function addPlate(slide, slideNo, opacityPanel = false) {
  slide.background.fill = PAPER;
  const platePath = path.join(REF_DIR, `slide-${String(slideNo).padStart(2, "0")}.png`);
  if (await pathExists(platePath)) {
    await addImage(
      slide,
      slideNo,
      { path: platePath, fit: "cover", alt: `Text-free art-direction plate for slide ${slideNo}` },
      { left: 0, top: 0, width: W, height: H },
      "art plate",
      platePath,
    );
  } else {
    await addImage(
      slide,
      slideNo,
      { dataUrl: FALLBACK_PLATE_DATA_URL, fit: "cover", alt: `Fallback blank art plate for slide ${slideNo}` },
      { left: 0, top: 0, width: W, height: H },
      "fallback art plate",
      "fallback-data-url",
    );
  }
  if (opacityPanel) {
    addShape(slide, "rect", 0, 0, W, H, "#FFFFFFB8", TRANSPARENT, 0, { slideNo, role: "plate readability overlay" });
  }
}

function addIconBadge(slide, slideNo, x, y, accent = ACCENT, kind = "signal") {
  addShape(slide, "ellipse", x, y, 54, 54, PAPER_96, INK, 1.2, { slideNo, role: "icon badge" });
  if (kind === "flow") {
    addShape(slide, "ellipse", x + 13, y + 18, 10, 10, accent, INK, 1, { slideNo, role: "icon glyph" });
    addShape(slide, "ellipse", x + 31, y + 27, 10, 10, accent, INK, 1, { slideNo, role: "icon glyph" });
    addShape(slide, "rect", x + 22, y + 25, 19, 3, INK, TRANSPARENT, 0, { slideNo, role: "icon glyph" });
  } else if (kind === "layers") {
    addShape(slide, "roundRect", x + 13, y + 15, 26, 13, accent, INK, 1, { slideNo, role: "icon glyph" });
    addShape(slide, "roundRect", x + 18, y + 24, 26, 13, GOLD, INK, 1, { slideNo, role: "icon glyph" });
    addShape(slide, "roundRect", x + 23, y + 33, 20, 10, CORAL, INK, 1, { slideNo, role: "icon glyph" });
  } else {
    addShape(slide, "rect", x + 16, y + 29, 6, 12, accent, TRANSPARENT, 0, { slideNo, role: "icon glyph" });
    addShape(slide, "rect", x + 25, y + 21, 6, 20, accent, TRANSPARENT, 0, { slideNo, role: "icon glyph" });
    addShape(slide, "rect", x + 34, y + 14, 6, 27, accent, TRANSPARENT, 0, { slideNo, role: "icon glyph" });
  }
}

function addCard(
  slide,
  slideNo,
  x,
  y,
  w,
  h,
  label,
  body,
  { accent = ACCENT, fill = PAPER_96, line = INK, iconKind = "signal", bodySize = 17 } = {},
) {
  if (h < 156) {
    throw new Error(`Card is too short for editable pro-deck copy: height=${h.toFixed(1)}, minimum=156.`);
  }
  addShape(slide, "roundRect", x, y, w, h, fill, line, 1.2, { slideNo, role: `card panel: ${label}` });
  addShape(slide, "rect", x, y, 8, h, accent, TRANSPARENT, 0, { slideNo, role: `card accent: ${label}` });
  addIconBadge(slide, slideNo, x + 22, y + 24, accent, iconKind);
  addText(slide, slideNo, label, x + 88, y + 22, w - 108, 28, {
    size: 15,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    role: "card label",
  });
  const wrapped = wrapText(body, Math.max(32, Math.floor(w / 11)));
  const bodyY = y + 86;
  const bodyH = h - (bodyY - y) - 22;
  if (bodyH < 54) {
    throw new Error(`Card body area is too short: height=${bodyH.toFixed(1)}, cardHeight=${h.toFixed(1)}, label=${JSON.stringify(label)}.`);
  }
  addText(slide, slideNo, wrapped, x + 24, bodyY, w - 48, bodyH, {
    size: bodySize,
    color: INK,
    face: BODY_FACE,
    role: `card body: ${label}`,
  });
}

function addMetricCard(slide, slideNo, x, y, w, h, metric, label, note = null, accent = ACCENT) {
  if (h < 132) {
    throw new Error(`Metric card is too short for editable pro-deck copy: height=${h.toFixed(1)}, minimum=132.`);
  }
  addShape(slide, "roundRect", x, y, w, h, PAPER_96, INK, 1.2, { slideNo, role: `metric panel: ${label}` });
  addShape(slide, "rect", x, y, w, 7, accent, TRANSPARENT, 0, { slideNo, role: `metric accent: ${label}` });
  addText(slide, slideNo, metric, x + 22, y + 24, w - 44, 54, {
    size: 34,
    color: INK,
    bold: true,
    face: TITLE_FACE,
    role: "metric value",
  });
  addText(slide, slideNo, label, x + 24, y + 82, w - 48, 38, {
    size: 16,
    color: GRAPHITE,
    face: BODY_FACE,
    role: "metric label",
  });
  if (note) {
    addText(slide, slideNo, note, x + 24, y + h - 42, w - 48, 22, {
      size: 10,
      color: MUTED,
      face: BODY_FACE,
      role: "metric note",
    });
  }
}

function addNotes(slide, body, sourceKeys) {
  const sourceLines = (sourceKeys || []).map((key) => `- ${SOURCES[key] || key}`).join("\n");
  slide.speakerNotes.setText(`${body || ""}\n\n[Sources]\n${sourceLines}`);
}

function addTagPill(slide, slideNo, x, y, w, label, fill = CORAL, textColor = WHITE) {
  addShape(slide, "roundRect", x, y, w, 26, fill, TRANSPARENT, 0, { slideNo, role: `tag pill: ${label}` });
  addText(slide, slideNo, label, x + 12, y + 5, w - 24, 16, {
    size: 11,
    color: textColor,
    bold: true,
    face: MONO_FACE,
    align: "center",
    checkFit: false,
    role: "tag label",
  });
}

function addHeader(slide, slideNo, kicker, idx, total, { support = false } = {}) {
  const headerColor = support ? CORAL : ACCENT_DARK;
  const markerColor = support ? CORAL : ACCENT;
  const ruleColor = support ? CORAL : INK;
  addText(slide, slideNo, String(kicker || "").toUpperCase(), 64, 34, 520, 24, {
    size: 13,
    color: headerColor,
    bold: true,
    face: MONO_FACE,
    checkFit: false,
    role: "header",
  });
  if (support) {
    addTagPill(slide, slideNo, 922, 30, 144, "RESPALDO", CORAL, WHITE);
  }
  addText(slide, slideNo, `${String(idx).padStart(2, "0")} / ${String(total).padStart(2, "0")}`, 1114, 34, 104, 24, {
    size: 13,
    color: headerColor,
    bold: true,
    face: MONO_FACE,
    align: "right",
    checkFit: false,
    role: "header",
  });
  addShape(slide, "rect", 64, 64, 1152, 2, ruleColor, TRANSPARENT, 0, { slideNo, role: "header rule" });
  addShape(slide, "ellipse", 57, 57, 16, 16, markerColor, INK, 2, { slideNo, role: "header marker" });
}

function addTitleBlock(slide, slideNo, title, subtitle = null, x = 64, y = 86, w = 780, dark = false) {
  const titleColor = dark ? PAPER : INK;
  const bodyColor = dark ? PAPER : GRAPHITE;
  addText(slide, slideNo, title, x, y, w, 142, {
    size: 40,
    color: titleColor,
    bold: true,
    face: TITLE_FACE,
    role: "title",
  });
  if (subtitle) {
    addText(slide, slideNo, subtitle, x + 2, y + 148, Math.min(w, 860), 70, {
      size: 19,
      color: bodyColor,
      face: BODY_FACE,
      role: "subtitle",
    });
  }
}

function addSummaryPanel(slide, slideNo, items, x = 84, y = 548, w = 1112, h = 100, label = "Puntos de analisis", accent = ACCENT) {
  addShape(slide, "roundRect", x, y, w, h, PAPER_96, INK, 1.2, { slideNo, role: `summary panel: ${label}` });
  addShape(slide, "rect", x, y, 8, h, accent, TRANSPARENT, 0, { slideNo, role: `summary accent: ${label}` });
  if (h < 100) {
    addText(slide, slideNo, label, x + 24, y + 10, 240, h - 20, {
      size: 12,
      color: ACCENT_DARK,
      bold: true,
      face: MONO_FACE,
      role: "summary header compact",
    });
    addText(slide, slideNo, items.join("  ·  "), x + 250, y + 10, w - 274, h - 20, {
      size: 12,
      color: INK,
      face: BODY_FACE,
      valign: "middle",
      role: "summary body compact",
    });
    return;
  }
  addText(slide, slideNo, label, x + 24, y + 16, 280, 22, {
    size: 13,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    checkFit: false,
    role: "summary header",
  });
  addText(slide, slideNo, items.map((item) => `• ${item}`), x + 24, y + 42, w - 48, h - 52, {
    size: 14,
    color: INK,
    face: BODY_FACE,
    role: "summary body",
  });
}

function addFormulaPanel(
  slide,
  slideNo,
  x,
  y,
  w,
  h,
  title,
  formula,
  lines = [],
  { accent = ACCENT, formulaSize = 22 } = {},
) {
  addShape(slide, "roundRect", x, y, w, h, WHITE, INK, 1.2, { slideNo, role: `formula panel: ${title}` });
  addShape(slide, "rect", x, y, w, 8, accent, TRANSPARENT, 0, { slideNo, role: `formula accent: ${title}` });
  addText(slide, slideNo, title, x + 22, y + 18, w - 44, 24, {
    size: 14,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    checkFit: false,
    role: "formula header",
  });
  const noteReserve = lines.length ? Math.max(58, lines.length * 18 + 18) : 18;
  const formulaRequired = requiredTextHeight(formula, formulaSize, 1.08, 54) + 8;
  const formulaH = lines.length
    ? Math.max(72, Math.min(h - 74 - noteReserve, formulaRequired))
    : Math.max(72, Math.min(h - 60, formulaRequired + 16));
  addText(slide, slideNo, formula, x + 22, y + 56, w - 44, formulaH, {
    size: formulaSize,
    color: INK,
    bold: false,
    face: MATH_FACE,
    role: "formula body",
  });
  if (lines.length) {
    const bodyY = y + 64 + formulaH;
    const bodyH = h - (bodyY - y) - 18;
    addText(slide, slideNo, lines.map((line) => `• ${line}`), x + 22, bodyY, w - 44, bodyH, {
      size: 13,
      color: GRAPHITE,
      face: BODY_FACE,
      role: "formula note",
    });
  }
}

function addPlaceholderPanel(slide, slideNo, x, y, w, h, title, placeholder, accent = ACCENT) {
  addShape(slide, "roundRect", x, y, w, h, WHITE, INK, 1.2, { slideNo, role: `placeholder panel: ${title}` });
  addShape(slide, "rect", x, y, w, 8, accent, TRANSPARENT, 0, { slideNo, role: `placeholder accent: ${title}` });
  addText(slide, slideNo, title, x + 22, y + 20, w - 44, 28, {
    size: 18,
    color: INK,
    bold: true,
    face: TITLE_FACE,
    role: "placeholder title",
  });
  addShape(slide, "rect", x + 24, y + 66, w - 48, h - 94, PAPER, GRAPHITE, 1.2, {
    slideNo,
    role: `inner placeholder: ${title}`,
  });
  addText(slide, slideNo, placeholder, x + 48, y + 66 + (h - 94) / 2 - 24, w - 96, 48, {
    size: 16,
    color: MUTED,
    face: BODY_FACE,
    align: "center",
    valign: "middle",
    role: "placeholder text",
  });
}

function addBulletPanel(slide, slideNo, x, y, w, h, title, bullets, accent = ACCENT) {
  addShape(slide, "roundRect", x, y, w, h, WHITE, INK, 1.2, { slideNo, role: `bullet panel: ${title}` });
  addShape(slide, "rect", x, y, 8, h, accent, TRANSPARENT, 0, { slideNo, role: `bullet accent: ${title}` });
  addText(slide, slideNo, title, x + 24, y + 18, w - 48, 28, {
    size: 16,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    role: "bullet panel title",
  });
  addText(slide, slideNo, bullets.map((item) => `• ${item}`), x + 24, y + 58, w - 48, h - 78, {
    size: 15,
    color: INK,
    face: BODY_FACE,
    role: "bullet panel body",
  });
}

function citationText(keys = []) {
  const parts = keys.map((key) => CITATIONS[key]).filter(Boolean);
  if (!parts.length) return "";
  return `Fuentes: ${parts.join(" · ")}`;
}

function addFooter(slide, slideNo, citations = []) {
  const citationLine = citationText(citations);
  if (citationLine) {
    addText(slide, slideNo, citationLine, 64, 668, 860, 12, {
      size: 8,
      color: MUTED,
      face: BODY_FACE,
      checkFit: false,
      role: "citation footer",
    });
  }
  addText(slide, slideNo, "Actividad 2 · Curso de Control · Plataforma antivibratoria activa", 64, 690, 760, 12, {
    size: 10,
    color: MUTED,
    face: BODY_FACE,
    checkFit: false,
    role: "footer",
  });
  addText(slide, slideNo, "Grupo / integrantes: completar", 952, 690, 264, 12, {
    size: 10,
    color: MUTED,
    face: BODY_FACE,
    align: "right",
    checkFit: false,
    role: "footer",
  });
}

async function slideAgenda(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC2", TRANSPARENT, 0, { slideNo: idx, role: "agenda contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: false });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  addBulletPanel(slide, idx, 84, 288, 520, 300, data.leftTitle, data.leftBullets, ACCENT);
  addBulletPanel(slide, idx, 676, 288, 520, 300, data.rightTitle, data.rightBullets, GOLD);
  addShape(slide, "roundRect", 84, 608, 1112, 44, PAPER_96, INK, 1.2, { slideNo: idx, role: "agenda note panel" });
  addText(slide, idx, data.note, 108, 620, 1064, 18, {
    size: 12,
    color: GRAPHITE,
    face: BODY_FACE,
    checkFit: false,
    role: "agenda note",
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideCover(presentation, idx) {
  const slideNo = idx;
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, slideNo);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFCC", TRANSPARENT, 0, { slideNo, role: "cover contrast overlay" });
  addShape(slide, "rect", 64, 86, 7, 455, ACCENT, TRANSPARENT, 0, { slideNo, role: "cover accent rule" });
  addText(slide, slideNo, data.kicker, 86, 88, 520, 26, {
    size: 13,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    role: "kicker",
  });
  addText(slide, slideNo, data.title, 82, 130, 820, 184, {
    size: 48,
    color: INK,
    bold: true,
    face: TITLE_FACE,
    role: "cover title",
  });
  addText(slide, slideNo, data.subtitle, 86, 326, 636, 90, {
    size: 20,
    color: GRAPHITE,
    face: BODY_FACE,
    role: "cover subtitle",
  });
  addShape(slide, "roundRect", 86, 456, 412, 92, PAPER_96, INK, 1.2, { slideNo, role: "cover moment panel" });
  addText(slide, slideNo, data.moment, 112, 478, 360, 40, {
    size: 23,
    color: INK,
    bold: true,
    face: TITLE_FACE,
    role: "cover moment",
  });
  addTagPill(slide, slideNo, 948, 88, 186, "DECK PRINCIPAL", ACCENT_DARK, WHITE);
  addShape(slide, "roundRect", 944, 140, 230, 164, PAPER_96, INK, 1.2, { slideNo, role: "cover side panel" });
  addText(slide, slideNo, "Mensaje clave", 968, 162, 182, 22, {
    size: 13,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    checkFit: false,
    role: "cover side header",
  });
  addText(
    slide,
    slideNo,
    ["• Rechazo de perturbaciones", "• Sensor ultrasónico sensible", "• Regulacion con r(t)=0", "• Seguimiento solo como caso complementario"],
    968,
    196,
    182,
    92,
    {
      size: 14,
      color: INK,
      face: BODY_FACE,
      role: "cover side body",
    },
  );
  addFooter(slide, slideNo, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideCards(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFB8", TRANSPARENT, 0, { slideNo: idx, role: "content contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 860);
  const cards = data.cards || [];
  const cols = Math.min(3, cards.length || 3);
  const cardW = (1112 - (cols - 1) * 24) / cols;
  const iconKinds = ["signal", "flow", "layers"];
  for (let cardIdx = 0; cardIdx < cols; cardIdx += 1) {
    const [label, body] = cards[cardIdx];
    const x = 84 + cardIdx * (cardW + 24);
    addCard(slide, idx, x, 370, cardW, 236, label, body, { iconKind: iconKinds[cardIdx % iconKinds.length] });
  }
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideMetrics(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFBD", TRANSPARENT, 0, { slideNo: idx, role: "metrics contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 820);
  const accents = [ACCENT, GOLD, CORAL];
  for (let metricIdx = 0; metricIdx < Math.min(3, data.metrics.length); metricIdx += 1) {
    const [metric, label, note] = data.metrics[metricIdx];
    addMetricCard(slide, idx, 92 + metricIdx * 370, 392, 330, 174, metric, label, note, accents[metricIdx % accents.length]);
  }
  if (data.summary?.length) {
    addSummaryPanel(slide, idx, data.summary, 84, 586, 1112, 72, "Lectura del problema");
  }
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideModel(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFBF", TRANSPARENT, 0, { slideNo: idx, role: "model contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 860);
  addBulletPanel(slide, idx, 84, 286, 424, 330, "Elementos del sistema", data.bullets, ACCENT);
  addPlaceholderPanel(slide, idx, 540, 286, 656, 330, data.placeholderTitle, data.placeholderText, GOLD);
  addShape(slide, "roundRect", 84, 632, 1112, 30, PAPER_96, INK, 1.2, { slideNo: idx, role: "model note panel" });
  addText(slide, idx, data.note, 106, 640, 1068, 14, {
    size: 11,
    color: GRAPHITE,
    face: BODY_FACE,
    checkFit: false,
    role: "model note",
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideEquations(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFBF", TRANSPARENT, 0, { slideNo: idx, role: "equation contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 860);
  addFormulaPanel(slide, idx, 84, 278, 540, 236, data.panels[0].title, data.panels[0].formula, data.panels[0].lines, {
    accent: ACCENT,
    formulaSize: 24,
  });
  addFormulaPanel(slide, idx, 656, 278, 540, 236, data.panels[1].title, data.panels[1].formula, data.panels[1].lines, {
    accent: GOLD,
    formulaSize: 24,
  });
  addSummaryPanel(slide, idx, data.footerLines, 84, 540, 1112, 106, data.footerTitle, CORAL);
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slidePlant(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFBF", TRANSPARENT, 0, { slideNo: idx, role: "plant contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 860);
  addFormulaPanel(slide, idx, 84, 268, 450, 360, data.leftTitle, data.leftFormula, data.leftLines, {
    accent: ACCENT,
    formulaSize: 18,
  });
  addFormulaPanel(slide, idx, 564, 268, 632, 360, data.rightTitle, data.rightFormula, data.rightLines, {
    accent: GOLD,
    formulaSize: 17,
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slidePlots(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  slide.background.fill = PAPER;
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, null, 64, 86, 900);
  addText(slide, idx, data.subtitle, 66, 218, 1000, 46, {
    size: 18,
    color: GRAPHITE,
    face: BODY_FACE,
    role: "subtitle",
  });
  const plots = data.plots || [];
  const hasTwo = plots.length > 1;
  const panelTop = 286;
  const panelHeight = hasTwo ? 248 : 276;
  const panelWidth = hasTwo ? 534 : 1112;
  const leftStart = 84;
  const gap = 44;
  for (let p = 0; p < plots.length; p += 1) {
    const [label, placeholder] = plots[p];
    const left = leftStart + p * (panelWidth + gap);
    addPlaceholderPanel(slide, idx, left, panelTop, panelWidth, panelHeight, label, placeholder, p % 2 === 0 ? ACCENT : GOLD);
  }
  if (data.summary?.length) {
    addSummaryPanel(slide, idx, data.summary, 84, hasTwo ? 562 : 578, 1112, hasTwo ? 86 : 72, "Lectura sugerida");
  }
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideReduction(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC2", TRANSPARENT, 0, { slideNo: idx, role: "reduction contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  addFormulaPanel(slide, idx, 84, 286, 540, 170, "Modelo reducido de sintonia", data.reducedFormula, [], {
    accent: ACCENT,
    formulaSize: 24,
  });
  addFormulaPanel(slide, idx, 656, 286, 540, 170, "Respuesta forzada equivalente", data.forcedFormula, [], {
    accent: GOLD,
    formulaSize: 20,
  });
  const cardW = (1112 - 48) / 3;
  const iconKinds = ["signal", "flow", "layers"];
  for (let i = 0; i < data.cards.length; i += 1) {
    const [label, body] = data.cards[i];
    addCard(slide, idx, 84 + i * (cardW + 24), 474, cardW, 192, label, body, { iconKind: iconKinds[i % iconKinds.length] });
  }
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideImc(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC2", TRANSPARENT, 0, { slideNo: idx, role: "imc contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  addFormulaPanel(slide, idx, 84, 282, 1112, 146, "Cadena de sintonia IMC", data.topFormula, [], {
    accent: ACCENT,
    formulaSize: 22,
  });
  const accents = [ACCENT, GOLD, CORAL];
  for (let metricIdx = 0; metricIdx < Math.min(3, data.metrics.length); metricIdx += 1) {
    const [metric, label, note] = data.metrics[metricIdx];
    addMetricCard(slide, idx, 92 + metricIdx * 370, 452, 330, 146, metric, label, note, accents[metricIdx % accents.length]);
  }
  addSummaryPanel(slide, idx, [data.finalLine], 84, 618, 1112, 40, "Resultado");
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slidePidBlock(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC0", TRANSPARENT, 0, { slideNo: idx, role: "pid contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: Boolean(data.support) });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  addFormulaPanel(slide, idx, 84, 286, 352, 240, "Forma ideal", data.idealFormula, [], { accent: ACCENT, formulaSize: 19 });
  addFormulaPanel(slide, idx, 464, 286, 352, 240, "Bloque PID filtrado", data.blockFormula, [], { accent: GOLD, formulaSize: 19 });
  addFormulaPanel(slide, idx, 844, 286, 352, 240, "Conversion", data.mappingFormula, [], { accent: CORAL, formulaSize: 18 });
  addSummaryPanel(slide, idx, [data.finalValues], 84, 550, 1112, 72, "Implementacion final");
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

function addTableCell(slide, slideNo, x, y, w, h, text, { bold = false, fill = WHITE, align = "center", face = BODY_FACE, size = 14, color = INK } = {}) {
  addShape(slide, "rect", x, y, w, h, fill, INK, 1, { slideNo, role: "table cell" });
  addText(slide, slideNo, text, x + 10, y + 10, w - 20, h - 20, {
    size,
    color,
    bold,
    face,
    align,
    valign: "middle",
    role: "table cell text",
  });
}

async function slideTable(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  slide.background.fill = PAPER;
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: true });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 880);
  const x = 84;
  const y = 286;
  const rowH = 52;
  const colW = [480, 158, 158, 158, 158];
  let cursorX = x;
  data.tableHeaders.forEach((header, headerIdx) => {
    addTableCell(slide, idx, cursorX, y, colW[headerIdx], rowH, header, {
      bold: true,
      fill: "#EDE7D9",
      face: MONO_FACE,
      size: 13,
    });
    cursorX += colW[headerIdx];
  });
  data.tableRows.forEach((row, rowIdx) => {
    let rowX = x;
    row.forEach((value, colIdx) => {
      addTableCell(slide, idx, rowX, y + rowH * (rowIdx + 1), colW[colIdx], rowH, value, {
        align: colIdx === 0 ? "left" : "center",
        size: 13,
      });
      rowX += colW[colIdx];
    });
  });
  addSummaryPanel(slide, idx, [data.note], 84, 586, 1112, 72, "Observacion metodologica", CORAL);
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideConclusions(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC2", TRANSPARENT, 0, { slideNo: idx, role: "conclusion contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: true });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  const cardW = 544;
  const cardH = 172;
  const positions = [
    [84, 286],
    [652, 286],
    [84, 476],
    [652, 476],
  ];
  const iconKinds = ["signal", "flow", "layers", "signal"];
  data.conclusions.forEach((body, itemIdx) => {
    const [x, y] = positions[itemIdx];
    addCard(slide, idx, x, y, cardW, cardH, `Conclusion ${itemIdx + 1}`, body, { iconKind: iconKinds[itemIdx] });
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideBonus(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFBF", TRANSPARENT, 0, { slideNo: idx, role: "bonus contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: true });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 860);
  addPlaceholderPanel(slide, idx, 84, 286, 660, 330, data.placeholderTitle, data.placeholderText, GOLD);
  addBulletPanel(slide, idx, 774, 286, 422, 330, "Como usar el bono", data.bullets, CORAL);
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideGridCards(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  await addPlate(slide, idx);
  addShape(slide, "rect", 0, 0, W, H, "#FFFFFFC2", TRANSPARENT, 0, { slideNo: idx, role: "grid contrast overlay" });
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: true });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 900);
  const positions = [
    [84, 268],
    [468, 268],
    [852, 268],
    [276, 478],
    [660, 478],
  ];
  const widths = [344, 344, 344, 344, 344];
  const heights = [184, 184, 184, 184, 184];
  const iconKinds = ["signal", "flow", "layers", "signal", "flow"];
  data.cards.forEach(([label, body], itemIdx) => {
    const [x, y] = positions[itemIdx];
    addCard(slide, idx, x, y, widths[itemIdx], heights[itemIdx], label, body, {
      iconKind: iconKinds[itemIdx],
      bodySize: 15,
    });
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function slideBackup(presentation, idx) {
  const data = SLIDES[idx - 1];
  const slide = presentation.slides.add();
  slide.background.fill = PAPER;
  addHeader(slide, idx, data.kicker, idx, SLIDES.length, { support: true });
  addTitleBlock(slide, idx, data.title, data.subtitle, 64, 86, 920);
  addFormulaPanel(slide, idx, 84, 286, 540, 168, data.panels[0].title, data.panels[0].formula, [], {
    accent: ACCENT,
    formulaSize: 18,
  });
  addFormulaPanel(slide, idx, 656, 286, 540, 168, data.panels[1].title, data.panels[1].formula, [], {
    accent: GOLD,
    formulaSize: 18,
  });
  addFormulaPanel(slide, idx, 84, 482, 1112, 138, data.panels[2].title, data.panels[2].formula, [], {
    accent: CORAL,
    formulaSize: 18,
  });
  addShape(slide, "roundRect", 84, 636, 1112, 28, PAPER_96, INK, 1.2, { slideNo: idx, role: "backup note panel" });
  addText(slide, idx, "Uso del slide", 106, 643, 120, 14, {
    size: 11,
    color: ACCENT_DARK,
    bold: true,
    face: MONO_FACE,
    checkFit: false,
    role: "backup note header",
  });
  addText(slide, idx, data.note, 232, 643, 942, 14, {
    size: 11,
    color: GRAPHITE,
    face: BODY_FACE,
    checkFit: false,
    role: "backup note body",
  });
  addFooter(slide, idx, data.citations);
  addNotes(slide, data.notes, data.sources);
}

async function createDeck() {
  await ensureDirs();
  if (!SLIDES.length) {
    throw new Error("SLIDES must contain at least one slide.");
  }
  const presentation = Presentation.create({ slideSize: { width: W, height: H } });
  for (let idx = 1; idx <= SLIDES.length; idx += 1) {
    const data = SLIDES[idx - 1];
    if (data.type === "cover") {
      await slideCover(presentation, idx);
    } else if (data.type === "agenda") {
      await slideAgenda(presentation, idx);
    } else if (data.type === "cards") {
      await slideCards(presentation, idx);
    } else if (data.type === "metrics") {
      await slideMetrics(presentation, idx);
    } else if (data.type === "model") {
      await slideModel(presentation, idx);
    } else if (data.type === "equations") {
      await slideEquations(presentation, idx);
    } else if (data.type === "plant") {
      await slidePlant(presentation, idx);
    } else if (data.type === "plots") {
      await slidePlots(presentation, idx);
    } else if (data.type === "reduction") {
      await slideReduction(presentation, idx);
    } else if (data.type === "imc") {
      await slideImc(presentation, idx);
    } else if (data.type === "pidblock") {
      await slidePidBlock(presentation, idx);
    } else if (data.type === "table") {
      await slideTable(presentation, idx);
    } else if (data.type === "conclusions") {
      await slideConclusions(presentation, idx);
    } else if (data.type === "bonus") {
      await slideBonus(presentation, idx);
    } else if (data.type === "gridcards") {
      await slideGridCards(presentation, idx);
    } else if (data.type === "backup") {
      await slideBackup(presentation, idx);
    } else {
      throw new Error(`Unknown slide type: ${data.type}`);
    }
  }
  return presentation;
}

async function saveBlobToFile(blob, filePath) {
  const bytes = new Uint8Array(await blob.arrayBuffer());
  await fs.writeFile(filePath, bytes);
}

async function writeInspectArtifact(presentation) {
  inspectRecords.unshift({
    kind: "deck",
    id: DECK_ID,
    slideCount: presentation.slides.count,
    slideSize: { width: W, height: H },
  });
  presentation.slides.items.forEach((slide, index) => {
    inspectRecords.splice(index + 1, 0, {
      kind: "slide",
      slide: index + 1,
      id: slide?.id || `slide-${index + 1}`,
    });
  });
  const lines = inspectRecords.map((record) => JSON.stringify(record)).join("\n") + "\n";
  await fs.writeFile(INSPECT_PATH, lines, "utf8");
}

async function currentRenderLoopCount() {
  const logPath = path.join(VERIFICATION_DIR, "render_verify_loops.ndjson");
  if (!(await pathExists(logPath))) return 0;
  const previous = await fs.readFile(logPath, "utf8");
  return previous.split(/\r?\n/).filter((line) => line.trim()).length;
}

async function nextRenderLoopNumber() {
  return (await currentRenderLoopCount()) + 1;
}

async function appendRenderVerifyLoop(presentation, previewPaths, pptxPath) {
  const logPath = path.join(VERIFICATION_DIR, "render_verify_loops.ndjson");
  const priorCount = await currentRenderLoopCount();
  const record = {
    kind: "render_verify_loop",
    deckId: DECK_ID,
    loop: priorCount + 1,
    maxLoops: MAX_RENDER_VERIFY_LOOPS,
    capReached: priorCount + 1 >= MAX_RENDER_VERIFY_LOOPS,
    timestamp: new Date().toISOString(),
    slideCount: presentation.slides.count,
    previewCount: previewPaths.length,
    previewDir: PREVIEW_DIR,
    inspectPath: INSPECT_PATH,
    pptxPath,
  };
  await fs.appendFile(logPath, JSON.stringify(record) + "\n", "utf8");
  return record;
}

async function verifyAndExport(presentation) {
  await ensureDirs();
  const nextLoop = await nextRenderLoopNumber();
  if (nextLoop > MAX_RENDER_VERIFY_LOOPS) {
    throw new Error(
      `Render/verify/fix loop cap reached: ${MAX_RENDER_VERIFY_LOOPS} total renders are allowed. ` +
        "Do not rerender; note any remaining visual issues in the final response.",
    );
  }
  await writeInspectArtifact(presentation);
  const previewPaths = [];
  for (let idx = 0; idx < presentation.slides.items.length; idx += 1) {
    const slide = presentation.slides.items[idx];
    const preview = await presentation.export({ slide, format: "png", scale: 1 });
    const previewPath = path.join(PREVIEW_DIR, `slide-${String(idx + 1).padStart(2, "0")}.png`);
    await saveBlobToFile(preview, previewPath);
    previewPaths.push(previewPath);
  }
  const pptxBlob = await PresentationFile.exportPptx(presentation);
  const pptxPath = path.join(OUT_DIR, "output.pptx");
  await pptxBlob.save(pptxPath);
  const loopRecord = await appendRenderVerifyLoop(presentation, previewPaths, pptxPath);
  return { pptxPath, loopRecord };
}

const presentation = await createDeck();
const result = await verifyAndExport(presentation);
console.log(result.pptxPath);
