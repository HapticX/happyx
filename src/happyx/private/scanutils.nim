#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#            
#             Changed by HapticX
#

##[
This module contains a `scanf`:idx: macro that can be used for extracting
substrings from an input string. This is often easier than regular expressions.
Some examples as an appetizer:

.. code-block:: nim
  # check if input string matches a triple of integers:
  const input = "(1,2,4)"
  var x, y, z: int
  if scanf(input, "($i,$i,$i)", x, y, z):
    echo "matches and x is ", x, " y is ", y, " z is ", z

  # check if input string matches an ISO date followed by an identifier followed
  # by whitespace and a floating point number:
  var year, month, day: int
  var identifier: string
  var myfloat: float
  if scanf(input, "$i-$i-$i $w$s$f", year, month, day, identifier, myfloat):
    echo "yes, we have a match!"

As can be seen from the examples, strings are matched verbatim except for
substrings starting with ``$``. These constructions are available:

=================   ========================================================
``$b``              Matches a binary integer. This uses ``parseutils.parseBin``.
``$o``              Matches an octal integer. This uses ``parseutils.parseOct``.
``$i``              Matches a decimal integer. This uses ``parseutils.parseInt``.
``$h``              Matches a hex integer. This uses ``parseutils.parseHex``.
``$f``              Matches a floating-point number. Uses ``parseFloat``.
``$w``              Matches an ASCII identifier: ``[A-Za-z_][A-Za-z_0-9]*``.
``$c``              Matches a single ASCII character.
``$s``              Skips optional whitespace.
``$$``              Matches a single dollar sign.
``$.``              Matches if the end of the input string has been reached.
``$*``              Matches until the token following the ``$*`` was found.
                    The match is allowed to be of 0 length.
``$+``              Matches until the token following the ``$+`` was found.
                    The match must consist of at least one char.
``${foo}``          User defined matcher. Uses the proc ``foo`` to perform
                    the match. See below for more details.
``$[foo]``          Call user defined proc ``foo`` to **skip** some optional
                    parts in the input string. See below for more details.
=================   ========================================================

Even though ``$*`` and ``$+`` look similar to the regular expressions ``.*``
and ``.+``, they work quite differently. There is no non-deterministic
state machine involved and the matches are non-greedy. ``[$*]``
matches ``[xyz]`` via ``parseutils.parseUntil``.

Furthermore no backtracking is performed, if parsing fails after a value
has already been bound to a matched subexpression this value is not restored
to its original value. This rarely causes problems in practice and if it does
for you, it's easy enough to bind to a temporary variable first.


Startswith vs full match
========================

``scanf`` returns true if the input string **starts with** the specified
pattern. If instead it should only return true if there is also nothing
left in the input, append ``$.`` to your pattern.


User definable matchers
=======================

One very nice advantage over regular expressions is that ``scanf`` is
extensible with ordinary Nim procs. The proc is either enclosed in ``${}``
or in ``$[]``. ``${}`` matches and binds the result
to a variable (that was passed to the ``scanf`` macro) while ``$[]`` merely
matches optional tokens without any result binding.


In this example, we define a helper proc ``someSep`` that skips some separators
which we then use in our scanf pattern to help us in the matching process:

.. code-block:: nim

  proc someSep(input: string; start: int; seps: set[char] = {':','-','.'}): int =
    # Note: The parameters and return value must match to what ``scanf`` requires
    result = 0
    while start+result < input.len and input[start+result] in seps: inc result

  if scanf(input, "$w$[someSep]$w", key, value):
    ...

It also possible to pass arguments to a user definable matcher:

.. code-block:: nim

  proc ndigits(input: string; intVal: var int; start: int; n: int): int =
    # matches exactly ``n`` digits. Matchers need to return -1 if nothing
    # matched or otherwise the number of processed chars.
    var x = 0
    var i = 0
    while i < n and i+start < input.len and input[i+start] in {'0'..'9'}:
      x = x * 10 + input[i+start].ord - '0'.ord
      inc i
    # only overwrite if we had a match
    if i == n:
      result = n
      intVal = x

  # match an ISO date extracting year, month, day at the same time.
  # Also ensure the input ends after the ISO date:
  var year, month, day: int
  if scanf("2013-01-03", "${ndigits(4)}-${ndigits(2)}-${ndigits(2)}$.", year, month, day):
    ...


The scanp macro
===============

This module also implements a ``scanp`` macro, which syntax somewhat resembles
an EBNF or PEG grammar, except that it uses Nim's expression syntax and so has
to use prefix instead of postfix operators.

==============   ===============================================================
``(E)``          Grouping
``*E``           Zero or more
``+E``           One or more
``?E``           Zero or One
``E{n,m}``       From ``n`` up to ``m`` times ``E``
``~E``           Not predicate
``a ^* b``       Shortcut for ``?(a *(b a))``. Usually used for separators.
``a ^+ b``       Shortcut for ``?(a +(b a))``. Usually used for separators.
``'a'``          Matches a single character
``{'a'..'b'}``   Matches a character set
``"s"``          Matches a string
``E -> a``       Bind matching to some action
``$_``           Access the currently matched character
==============   ===============================================================

Note that unordered or ordered choice operators (``/``, ``|``) are
not implemented.

Simple example that parses the ``/etc/passwd`` file line by line:

.. code-block:: nim

  const
    etc_passwd = """root:x:0:0:root:/root:/bin/bash
  daemon:x:1:1:daemon:/usr/sbin:/bin/sh
  bin:x:2:2:bin:/bin:/bin/sh
  sys:x:3:3:sys:/dev:/bin/sh
  nobody:x:65534:65534:nobody:/nonexistent:/bin/sh
  messagebus:x:103:107::/var/run/dbus:/bin/false
  """

  proc parsePasswd(content: string): seq[string] =
    result = @[]
    var idx = 0
    while true:
      var entry = ""
      if scanp(content, idx, +(~{'\L', '\0'} -> entry.add($_)), '\L'):
        result.add entry
      else:
        break

The ``scanp`` maps the grammar code into Nim code that performs the parsing.
The parsing is performed with the help of 3 helper templates that that can be
implemented for a custom type.

These templates need to be named ``atom`` and ``nxt``. ``atom`` should be
overloaded to handle both single characters and sets of character.

.. code-block:: nim

  import std/streams

  template atom(input: Stream; idx: int; c: char): bool =
    ## Used in scanp for the matching of atoms (usually chars).
    peekChar(input) == c

  template atom(input: Stream; idx: int; s: set[char]): bool =
    peekChar(input) in s

  template nxt(input: Stream; idx, step: int = 1) =
    inc(idx, step)
    setPosition(input, idx)

  if scanp(content, idx, +( ~{'\L', '\0'} -> entry.add(peekChar($input))), '\L'):
    result.add entry

Calling ordinary Nim procs inside the macro is possible:

.. code-block:: nim

  proc digits(s: string; intVal: var int; start: int): int =
    var x = 0
    while result+start < s.len and s[result+start] in {'0'..'9'} and s[result+start] != ':':
      x = x * 10 + s[result+start].ord - '0'.ord
      inc result
    intVal = x

  proc extractUsers(content: string): seq[string] =
    # Extracts the username and home directory
    # of each entry (with UID greater than 1000)
    const
      digits = {'0'..'9'}
    result = @[]
    var idx = 0
    while true:
      var login = ""
      var uid = 0
      var homedir = ""
      if scanp(content, idx, *(~ {':', '\0'}) -> login.add($_), ':', * ~ ':', ':',
              digits($input, uid, $index), ':', *`digits`, ':', * ~ ':', ':',
              *('/', * ~{':', '/'}) -> homedir.add($_), ':', *('/', * ~{'\L', '/'}), '\L'):
        if uid >= 1000:
          result.add login & " " & homedir
      else:
        break

When used for matching, keep in mind that likewise scanf, no backtracking
is performed.

.. code-block:: nim

  proc skipUntil(s: string; until: string; unless = '\0'; start: int): int =
    # Skips all characters until the string `until` is found. Returns 0
    # if the char `unless` is found first or the end is reached.
    var i = start
    var u = 0
    while true:
      if i >= s.len or s[i] == unless:
        return 0
      elif s[i] == until[0]:
        u = 1
        while i+u < s.len and u < until.len and s[i+u] == until[u]:
          inc u
        if u >= until.len: break
      inc(i)
    result = i+u-start

  iterator collectLinks(s: string): string =
    const quote = {'\'', '"'}
    var idx, old = 0
    var res = ""
    while idx < s.len:
      old = idx
      if scanp(s, idx, "<a", skipUntil($input, "href=", '>', $index),
              `quote`, *( ~`quote`) -> res.add($_)):
        yield res
        res = ""
      idx = old + 1

  for r in collectLinks(body):
    echo r

In this example both macros are combined seamlessly in order to maximise
efficiency and perform different checks.

.. code-block:: nim

  iterator parseIps*(soup: string): string =
    ## ipv4 only!
    const digits = {'0'..'9'}
    var a, b, c, d: int
    var buf = ""
    var idx = 0
    while idx < soup.len:
      if scanp(soup, idx, (`digits`{1,3}, '.', `digits`{1,3}, '.',
               `digits`{1,3}, '.', `digits`{1,3}) -> buf.add($_)):
        discard buf.scanf("$i.$i.$i.$i", a, b, c, d)
        if (a >= 0 and a <= 254) and
           (b >= 0 and b <= 254) and
           (c >= 0 and c <= 254) and
           (d >= 0 and d <= 254):
          yield buf
      buf.setLen(0) # need to clear `buf` each time, cause it might contain garbage
      idx.inc

]##


import macros, parseutils
import std/private/since

when defined(nimPreviewSlimSystem):
  import std/assertions


proc conditionsToIfChain(n, idx, res: NimNode; start: int): NimNode =
  assert n.kind == nnkStmtList
  if start >= n.len: return newAssignment(res, newLit true)
  var ifs: NimNode = nil
  if n[start+1].kind == nnkEmpty:
    ifs = conditionsToIfChain(n, idx, res, start+3)
  else:
    ifs = newIfStmt((n[start+1],
                    newTree(nnkStmtList, newCall(bindSym"inc", idx, n[start+2]),
                                     conditionsToIfChain(n, idx, res, start+3))))
  result = newTree(nnkStmtList, n[start], ifs)

proc notZero(x: NimNode): NimNode = newCall(bindSym"!=", x, newLit 0)

proc buildUserCall(x: string; args: varargs[NimNode]): NimNode =
  let y = parseExpr(x)
  result = newTree(nnkCall)
  if y.kind in nnkCallKinds: result.add y[0]
  else: result.add y
  for a in args: result.add a
  if y.kind in nnkCallKinds:
    for i in 1..<y.len: result.add y[i]

macro scanf*(input: string; pattern: static[string]; results: varargs[typed]): bool =
  ## See top level documentation of this module about how ``scanf`` works.
  template matchBind(parser) {.dirty.} =
    var resLen = genSym(nskLet, "resLen")
    conds.add newLetStmt(resLen, newCall(bindSym(parser), inp, results[i], idx))
    conds.add resLen.notZero
    conds.add resLen

  template at(s: string; i: int): char = (if i < s.len: s[i] else: '\0')
  template matchError() =
    error("type mismatch between pattern '$" & pattern[p] & "' (position: " & $p &
      ") and " & $getTypeInst(results[i]) & " var '" & repr(results[i]) & "'")

  var i = 0
  var p = 0
  var idx = genSym(nskVar, "idx")
  var res = genSym(nskVar, "res")
  let inp = genSym(nskLet, "inp")
  result = newTree(nnkStmtListExpr, newLetStmt(inp, input),
                   newVarStmt(idx, newLit 0), newVarStmt(res, newLit false))
  var conds = newTree(nnkStmtList)
  var fullMatch = false
  while p < pattern.len:
    if pattern[p] == '$':
      inc p
      case pattern[p]
      of '$':
        var resLen = genSym(nskLet, "resLen")
        conds.add newLetStmt(resLen, newCall(bindSym"skip", inp,
                                             newLit($pattern[p]), idx))
        conds.add resLen.notZero
        conds.add resLen
      of 'w':
        if i < results.len and getType(results[i]).typeKind == ntyString:
          matchBind "parseIdent"
        else:
          matchError
        inc i
      of 'c':
        if i < results.len and getType(results[i]).typeKind == ntyChar:
          matchBind "parseChar"
        else:
          matchError
        inc i
      of 'b':
        if i < results.len and getType(results[i]).typeKind == ntyInt:
          matchBind "parseBin"
        else:
          matchError
        inc i
      of 'o':
        if i < results.len and getType(results[i]).typeKind == ntyInt:
          matchBind "parseOct"
        else:
          matchError
        inc i
      of 'i':
        if i < results.len and getType(results[i]).typeKind == ntyInt:
          matchBind "parseInt"
        else:
          matchError
        inc i
      of 'h':
        if i < results.len and getType(results[i]).typeKind == ntyInt:
          matchBind "parseHex"
        else:
          matchError
        inc i
      of 'f':
        if i < results.len and getType(results[i]).typeKind == ntyFloat:
          matchBind "parseFloat"
        else:
          matchError
        inc i
      of 's':
        conds.add newCall(bindSym"inc", idx,
                          newCall(bindSym"skipWhitespace", inp, idx))
        conds.add newEmptyNode()
        conds.add newEmptyNode()
      of '.':
        if p == pattern.len-1:
          fullMatch = true
        else:
          error("invalid format string")
      of '*', '+':
        if i < results.len and getType(results[i]).typeKind == ntyString:
          var min = ord(pattern[p] == '+')
          var q = p+1
          var token = ""
          while q < pattern.len and pattern[q] != '$':
            token.add pattern[q]
            inc q
          var resLen = genSym(nskLet, "resLen")
          conds.add newLetStmt(resLen, newCall(bindSym"parseUntil", inp,
              results[i], newLit(token), idx))
          conds.add newCall(bindSym">=", resLen, newLit min)
          conds.add resLen
        else:
          matchError
        inc i
      of '{':
        inc p
        var nesting = 0
        let start = p
        while true:
          case pattern.at(p)
          of '{': inc nesting
          of '}':
            if nesting == 0: break
            dec nesting
          of '\0': error("expected closing '}'")
          else: discard
          inc p
        let expr = pattern.substr(start, p-1)
        if i < results.len:
          var resLen = genSym(nskLet, "resLen")
          conds.add newLetStmt(resLen, buildUserCall(expr, inp, results[i], idx))
          conds.add newCall(bindSym"!=", resLen, newLit(-1))
          conds.add resLen
        else:
          error("no var given for $" & expr & " (position: " & $p & ")")
        inc i
      of '[':
        inc p
        var nesting = 0
        let start = p
        while true:
          case pattern.at(p)
          of '[': inc nesting
          of ']':
            if nesting == 0: break
            dec nesting
          of '\0': error("expected closing ']'")
          else: discard
          inc p
        let expr = pattern.substr(start, p-1)
        conds.add newCall(bindSym"inc", idx, buildUserCall(expr, inp, idx))
        conds.add newEmptyNode()
        conds.add newEmptyNode()
      else: error("invalid format string")
      inc p
    else:
      var token = ""
      while p < pattern.len and pattern[p] != '$':
        token.add pattern[p]
        inc p
      var resLen = genSym(nskLet, "resLen")
      conds.add newLetStmt(resLen, newCall(bindSym"skip", inp, newLit(token), idx))
      conds.add resLen.notZero
      conds.add resLen
  result.add conditionsToIfChain(conds, idx, res, 0)
  if fullMatch:
    result.add newCall(bindSym"and", res,
      newCall(bindSym">=", idx, newCall(bindSym"len", inp)))
  else:
    result.add res
