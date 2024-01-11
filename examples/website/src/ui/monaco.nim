

{.emit: """//js

monaco.languages.register({id: 'nim'});
monaco.languages.setMonarchTokensProvider('nim', {
  defaultToken: '',
  tokenPostfix: '.nim',

  keywords: [
    'addr', 'and', 'as', 'asm', 'bind', 'block', 'break', 'case', 'cast', 'concept', 'const', 'continue', 'converter',
    'defer', 'discard', 'distinct', 'div', 'elif', 'else', 'end', 'enum', 'except', 'export', 'finally', 'for', 'from',
    'func', 'if', 'import', 'in', 'include', 'interface', 'is', 'isnot', 'iterator', 'let', 'macro', 'method', 'mixin',
    'mod', 'nil', 'not', 'notin', 'object', 'of', 'or', 'out', 'proc', 'ptr', 'raise', 'ref', 'return', 'shl', 'shr',
    'template', 'try', 'tuple', 'type', 'using', 'var', 'when', 'while', 'with', 'without', 'xor', 'yield',
	  'component', 'pathParam', 'model', 'use', 'appRoutes'
  ],

  symbols: /[!@$%^&*+\-=;:\\|<>\/?]+/,

  types: [
    'int', 'int8', 'int16', 'int32', 'int64',
    'uint', 'uint8', 'uint16', 'uint32', 'uint64',
    'float', 'float32', 'float64',
    'bool', 'char', 'string', 'cstring', 'pointer', 'range', 'seq', 'openArray',
	  'void', 'openarray', 'varargs', 'cint', 'cfloat', 'cdouble', 'array',
  ],

  stdfuncs: [
    "echo", "toSeq", "addr", "and", "or", "not", 'chr', "clamp",
    "compiles", "declared", "declaredInScope", "alloc", "dealloc",
    "div", "mod", "inc", "dec", "shr", "shl"
  ],

  brackets: [
    { open: '{', close: '}', token: 'delimiter.curly' },
    { open: '[', close: ']', token: 'delimiter.bracket' },
    { open: '(', close: ')', token: 'delimiter.parenthesis' }
  ],

  tokenizer: {
    root: [
	  { include: '@pragmas' },
      { include: '@whitespace' },
      { include: '@numbers' },
      { include: '@strings' },

      [/[,;]/, 'delimiter'],
      [/[{}\[\]()]/, '@brackets'],
      [/\@\w+/, 'keyword'],
      [/[A-Z][a-zA-Z_0-9]*/, 'constructor'],
      [/@symbols/, 'operator'],

      [/[a-zA-Z_]\w*/, {
        cases: {
          '@keywords': 'keyword',
          '@types': 'type',
          '@stdfuncs': 'keyword',
          '@default': 'identifier'
        }
      }]
    ],

    // Deal with white space, including single and multi-line comments
    whitespace: [
      [/\s+/, 'white'],
      [/(#.*$)/, 'comment'],
    ],
    endDocString: [
      [/'/, 'string.escape', '@popall'],
      [/.*$/, 'string']
    ],
    endDblDocString: [
      [/"/, 'string.escape', '@popall'],
      [/.*$/, 'string']
    ],

    // Recognize hex, negatives, decimals, imaginaries, longs, and scientific notation
    numbers: [
      [/-?0x([abcdef]|[ABCDEF]|\d)+[lL]?/, 'number.hex'],
      [/-?(\d*\.)?\d+([eE][+\-]?\d+)?[jJ]?[lL]?/, 'number']
    ],

    // Recognize strings, including those broken across lines with \ (but not without)
    strings: [
      [/'$/, 'string.escape', '@popall'],
      [/'/, 'string.escape', '@stringBody'],
      [/"$/, 'string.escape', '@popall'],
      [/"/, 'string.escape', '@dblStringBody']
    ],
    pragmas: [
      [/{\./, 'identifier', '@pragmaBody']
    ],
    pragmaBody: [
      { include: '@whitespace' },
      { include: '@numbers' },
      { include: '@strings' },
      [/\b[a-zA-Z]\w*\b/, 'keyword'],
      [/\./, 'identifier', '@pop'],
      [/\}/, 'identifier', '@pop']
    ],
    stringBody: [
      [/'/, 'string.escape', '@popall'],
      [/./, 'string'],
      [/\\./, 'string'],
      [/'/, 'string.escape', '@popall'],
      [/\\$/, 'string']
    ],
    dblStringBody: [
      [/"/, 'string.escape', '@popall'],
      [/./, 'string'],
      [/\\./, 'string'],
      [/"/, 'string.escape', '@popall'],
      [/\\$/, 'string']
    ]
  }
});

monaco.languages.registerCompletionItemProvider('nim', {
  provideCompletionItems: (model, position) => {
    const suggestions = [{
      label: 'proc',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'proc ${1:name}(${2:arguments}): ${3:void} =\n  $0',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'async proc',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'proc ${1:name}(${2:arguments}): ${3:void} {.async.} =\n  $0',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'func',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'func ${1:name}(${2:arguments}): ${3:void} =\n  $0',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'async func',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'func ${1:name}(${2:arguments}): ${3:void} {.async.} =\n  $0',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'component',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'component ${1:ComponentName}:\n  `template`:\n    tDiv:\n      ${0:"Hello, world!"}',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'appRoutes',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'appRoutes "root":\n  "/start":\n    ${0:"Hello, world!"}',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'if',
      kind: monaco.languages.CompletionItemKind.Keyword,
      insertText: 'if ${1:codition}:\n  ${0:body}',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'echo',
      kind: monaco.languages.CompletionItemKind.Function,
      insertText: 'echo ${0:"hello world!"}',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }, {
      label: 'quit',
      kind: monaco.languages.CompletionItemKind.Function,
      insertText: 'quit',
      insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
    }];

    return { suggestions };
  },
});


// Define a new theme that contains only rules that match this language
monaco.editor.defineTheme("nim-theme", {
	base: "vs-dark",
	inherit: true,
	rules: [
		{ token: "keyword", foreground: "ff79c6" },
		{ token: "operator", foreground: "ff79c6" },
		{ token: "type", foreground: "8be9fd" },
		{ token: "constructor", foreground: "8be9fd", fontStyle: "bold" },
		{ token: "number", foreground: "bd93f9" },
		{ token: "string", foreground: "f1fa8c" },
		{ token: "comment", foreground: "6272a4" },
	],
	colors: {
		"editor.foreground": "#f8f8f2",
		"editor.background": "#2b2e3b",
    "editor.lineHighlightBorder": "#f8f8f250",
  },
});

""".}
