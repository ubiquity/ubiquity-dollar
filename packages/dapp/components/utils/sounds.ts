export const note = (
  frequency: number | number[],
  meta?: {
    type?: "sine" | "square" | "sawtooth" | "triangle" | "custom";
    volume?: number;
    sustain?: number;
    chord?: (() => void)[] | boolean;
    reverb?: number;
  },
  callback?: () => void
): void => {
  if (typeof window === "undefined") return;
  const context = new (window.AudioContext || window.webkitAudioContext)();

  if (!context) return console.log("No AudioContext available");

  if (!meta) meta = {};
  const undef = void 0;
  if (meta.type == undef) meta.type = "sine";
  if (meta.volume == undef) meta.volume = 0.03125;
  if (meta.sustain == undef) meta.sustain = 0;
  if (meta.chord == undef) meta.chord = false;
  if (meta.reverb == undef) meta.reverb = 0.25;
  // console.log(JSON.stringify(meta, null, '\t'));
  if (typeof frequency !== "number") {
    let x = frequency.length;
    while (x--) {
      if (x) note(frequency[x], meta);
      else return note(frequency[x], meta, callback);
    }
  }
  if (typeof frequency === "number") {
    const o = context.createOscillator();
    const g = context.createGain();
    o.type = meta.type;
    o.connect(g);
    g.gain.value = meta.volume;
    o.frequency.value = frequency;
    g.connect(context.destination);
    o.start(0);

    if (!meta.chord) {
      g.gain.setTargetAtTime(0, context.currentTime + meta.sustain, meta.reverb);
    } else if (Array.isArray(meta.chord))
      meta.chord.push(
        (function (g, context, meta) {
          return () => {
            g.gain.setTargetAtTime(0, context.currentTime + (meta.sustain ?? 0), meta.reverb ?? 0);
          };
        })(g, context, meta)
      );
  }

  if (callback) {
    if (Array.isArray(meta.chord)) {
      let x = meta.chord.length;
      while (x--) meta.chord[x]();
    }
    callback();
  }
};

export const enterSound = () => {
  play([[950], [950, 1250], [1250, 1900], [1600, 1900]], 100, {
    reverb: 0.25,
    type: "sine",
  });
};

export const notes = [
  [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87],
  [32.7, 34.65, 36.71, 38.89, 41.2, 43.65, 46.25, 49.0, 51.91, 55.0, 58.27, 61.74],
  [65.41, 69.3, 73.42, 77.78, 82.41, 87.31, 92.5, 98.0, 103.8, 110.0, 116.5, 123.5],
  [130.8, 138.6, 146.8, 155.6, 164.8, 174.6, 185.0, 196.0, 207.7, 220.0, 233.1, 246.9],
  [261.6, 277.2, 293.7, 311.1, 329.6, 349.2, 370.0, 392.0, 415.3, 440.0, 466.2, 493.9],
  [523.3, 554.4, 587.3, 622.3, 659.3, 698.5, 740.0, 784.0, 830.6, 880.0, 932.3, 987.8],
  [1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976],
  [2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951],
  [4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902],
];

export const chipNote = () =>
  note(9250, {
    reverb: 0,
    sustain: 1 / 32,
    volume: 1 / 256,
    type: "sawtooth",
  });

export const play = (
  notes: number[] | number[][],
  speed: number,
  meta: {
    type?: "sine" | "square" | "sawtooth" | "triangle" | "custom";
    volume?: number;
    sustain?: number;
    chord?: (() => void)[] | boolean;
    reverb?: number;
  }
) =>
  note(notes.shift() ?? 0, meta, () => {
    if (notes.length)
      setTimeout(function () {
        play(notes, speed, meta);
      }, speed);
  });
