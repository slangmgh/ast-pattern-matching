import astmatching

# TODO test on matching failures

static:
  template testPattern(pattern, astArg: untyped): untyped =
    let ast = quote do: `astArg`

    ast.matchAst:
    of `pattern`:
      echo "ok"
    else:
      echo "fail"

  testPattern nnkIntLit(42), 42
  testPattern nnkInt8Lit(42), 42'i8
  testPattern nnkInt16Lit(42), 42'i16
  testPattern nnkInt32Lit(42), 42'i32
  testPattern nnkInt64Lit(42), 42'i64
  testPattern nnkUInt8Lit(42), 42'u8
  testPattern nnkUInt16Lit(42), 42'u16
  testPattern nnkUInt32Lit(42), 42'u32
  testPattern nnkUInt64Lit(42), 42'u64
  testPattern nnkFloat64Lit(42.0), 42.0
  testPattern nnkFloat32Lit(42.0), 42.0'f32
  testPattern nnkFloat64Lit(42.0), 42.0'f64
  testPattern nnkStrLit("abc"), "abc"
  testPattern nnkRStrLit("abc"), r"abc"
  testPattern nnkTripleStrLit("abc"), """abc"""
  testPattern nnkCharLit(32), ' '
  testPattern nnkNilLit(), nil
  testPattern nnkIdent("myIdentifier"), myIdentifier


#[

this should be converted into tests

-----------------                ---------------------------------------------

Identifiers are ``nnkIdent`` nodes. After the name lookup pass these nodes
get transferred into ``nnkSym`` nodes.


Calls/expressions
=================

Command call
------------

Concrete syntax:

.. code-block:: nim
  echo "abc", "xyz"

AST:

.. code-block:: nim
  nnkCommand(
    nnkIdent(!"echo"),
    nnkStrLit("abc"),
    nnkStrLit("xyz")
  )


Call with ``()``
----------------

Concrete syntax:

.. code-block:: nim
  echo("abc", "xyz")

AST:

.. code-block:: nim
  nnkCall(
    nnkIdent(!"echo"),
    nnkStrLit("abc"),
    nnkStrLit("xyz")
  )


Infix operator call
-------------------

Concrete syntax:

.. code-block:: nim
  "abc" & "xyz"

AST:

.. code-block:: nim
  nnkInfix(
    nnkIdent(!"&"),
    nnkStrLit("abc"),
    nnkStrLit("xyz")
  )

Note that with multiple infix operators, the command is parsed by operator
precedence.

Concrete syntax:

.. code-block:: nim
  5 + 3 * 4

AST:

.. code-block:: nim
  nnkInfix(
    nnkIdent(!"+"),
    nnkIntLit(5),
    nnkInfix(
      nnkIdent(!"*"),
      nnkIntLit(3),
      nnkIntLit(4)
    )
  )

As a side note, if you choose to use infix operators in a prefix form, the AST
behaves as a
[parenthetical function call](./macros.html#calls-expressions-call-with) with
``nnkAccQuoted``, as follows:

Concrete syntax:

.. code-block:: nim
  `+`(3, 4)

AST:

.. code-block:: nim
  nnkCall(
    nnkAccQuoted(
      nnkIdent(!"+")
    ),
    nnkIntLit(3),
    nnkIntLit(4)
  )

Prefix operator call
--------------------

Concrete syntax:

.. code-block:: nim
  ? "xyz"

AST:

.. code-block:: nim
  nnkPrefix(
    nnkIdent(!"?"),
    nnkStrLit("abc")
  )


Postfix operator call
---------------------

**Note:** There are no postfix operators in Nim. However, the
``nnkPostfix`` node is used for the *asterisk export marker* ``*``:

Concrete syntax:

.. code-block:: nim
  identifier*

AST:

.. code-block:: nim
  nnkPostfix(
    nnkIdent(!"*"),
    nnkIdent(!"identifier")
  )


Call with named arguments
-------------------------

Concrete syntax:

.. code-block:: nim
  writeLine(file=stdout, "hallo")

AST:

.. code-block:: nim
  nnkCall(
    nnkIdent(!"writeLine"),
    nnkExprEqExpr(
      nnkIdent(!"file"),
      nnkIdent(!"stdout")
    ),
    nnkStrLit("hallo")
  )

Call with raw string literal
----------------------------

This is used, for example, in the ``bindSym`` examples
[here](http://nim-lang.org/docs/manual.html#macros-bindsym) and with
``re"some regexp"`` in the regular expression module.

Concrete syntax:

.. code-block:: nim
  echo"abc"

AST:

.. code-block:: nim
  nnkCallStrLit(
    nnkIdent(!"echo"),
    nnkRStrLit("hello")
  )

Dereference operator ``[]``
---------------------------

Concrete syntax:

.. code-block:: nim
  x[]

AST:

.. code-block:: nim
  nnkDerefExpr(nnkIdent(!"x"))


Addr operator
-------------

Concrete syntax:

.. code-block:: nim
  addr(x)

AST:

.. code-block:: nim
  nnkAddr(nnkIdent(!"x"))


Cast operator
-------------

Concrete syntax:

.. code-block:: nim
  cast[T](x)

AST:

.. code-block:: nim
  nnkCast(nnkIdent(!"T"), nnkIdent(!"x"))


Object access operator ``.``
----------------------------

Concrete syntax:

.. code-block:: nim
  x.y

AST:

.. code-block:: nim
  nnkDotExpr(nnkIdent(!"x"), nnkIdent(!"y"))

If you use Nim's flexible calling syntax (as in ``x.len()``), the result is the
same as above but wrapped in an ``nnkCall``.


Array access operator ``[]``
----------------------------

Concrete syntax:

.. code-block:: nim
  x[y]

AST:

.. code-block:: nim
  nnkBracketExpr(nnkIdent(!"x"), nnkIdent(!"y"))


Parentheses
-----------

Parentheses for affecting operator precedence or tuple construction
are built with the ``nnkPar`` node.

Concrete syntax:

.. code-block:: nim
  (1, 2, (3))

AST:

.. code-block:: nim
  nnkPar(nnkIntLit(1), nnkIntLit(2), nnkPar(nnkIntLit(3)))


Curly braces
------------

Curly braces are used as the set constructor.

Concrete syntax:

.. code-block:: nim
  {1, 2, 3}

AST:

.. code-block:: nim
  nnkCurly(nnkIntLit(1), nnkIntLit(2), nnkIntLit(3))

When used as a table constructor, the syntax is different.

Concrete syntax:

.. code-block:: nim
  {a: 3, b: 5}

AST:

.. code-block:: nim
  nnkTableConstr(
    nnkExprColonExpr(nnkIdent(!"a"), nnkIntLit(3)),
    nnkExprColonExpr(nnkIdent(!"b"), nnkIntLit(5))
  )


Brackets
--------

Brackets are used as the array constructor.

Concrete syntax:

.. code-block:: nim
  [1, 2, 3]

AST:

.. code-block:: nim
  nnkBracket(nnkIntLit(1), nnkIntLit(2), nnkIntLit(3))


Ranges
------

Ranges occur in set constructors, case statement branches, or array slices.
Internally, the node kind ``nnkRange`` is used, but when constructing the
AST, construction with ``..`` as an infix operator should be used instead.

Concrete syntax:

.. code-block:: nim
  1..3

AST:

.. code-block:: nim
  nnkInfix(
    nnkIdent(!".."),
    nnkIntLit(1),
    nnkIntLit(3)
  )

Example code:

.. code-block:: nim
  macro genRepeatEcho(): stmt =
    result = newNimNode(nnkStmtList)

    var forStmt = newNimNode(nnkForStmt) # generate a for statement
    forStmt.add(ident("i")) # use the variable `i` for iteration

    var rangeDef = newNimNode(nnkInfix).add(
      ident("..")).add(
      newIntLitNode(3),newIntLitNode(5)) # iterate over the range 3..5

    forStmt.add(rangeDef)
    forStmt.add(newCall(ident("echo"), newIntLitNode(3))) # meat of the loop
    result.add(forStmt)

  genRepeatEcho() # gives:
                  # 3
                  # 3
                  # 3


If expression
-------------

The representation of the ``if`` expression is subtle, but easy to traverse.

Concrete syntax:

.. code-block:: nim
  if cond1: expr1 elif cond2: expr2 else: expr3

AST:

.. code-block:: nim
  nnkIfExpr(
    nnkElifExpr(cond1, expr1),
    nnkElifExpr(cond2, expr2),
    nnkElseExpr(expr3)
  )

Documentation Comments
----------------------

Double-hash (``##``) comments in the code actually have their own format,
using ``strVal`` to get and set the comment text. Single-hash (``#``)
comments are ignored.

Concrete syntax:

.. code-block:: nim
  ## This is a comment
  ## This is part of the first comment
  stmt1
  ## Yet another

AST:

.. code-block:: nim
  nnkCommentStmt() # only appears once for the first two lines!
  stmt1
  nnkCommentStmt() # another nnkCommentStmt because there is another comment
                   # (separate from the first)

Pragmas
-------

One of Nim's cool features is pragmas, which allow fine-tuning of various
aspects of the language. They come in all types, such as adorning procs and
objects, but the standalone ``emit`` pragma shows the basics with the AST.

Concrete syntax:

.. code-block:: nim
  {.emit: "#include <stdio.h>".}

AST:

.. code-block:: nim
  nnkPragma(
    nnkExprColonExpr(
      nnkIdent(!"emit"),
      nnkStrLit("#include <stdio.h>") # the "argument"
    )
  )

As many ``nnkIdent`` appear as there are pragmas between ``{..}``. Note that
the declaration of new pragmas is essentially the same:

Concrete syntax:

.. code-block:: nim
  {.pragma: cdeclRename, cdecl.}

AST:

.. code-block:: nim
  nnkPragma(
    nnkExprColonExpr(
      nnkIdent(!"pragma"), # this is always first when declaring a new pragma
      nnkIdent(!"cdeclRename") # the name of the pragma
    ),
    nnkIdent(!"cdecl")
  )

Statements
==========

If statement
------------

The representation of the if statement is subtle, but easy to traverse. If
there is no ``else`` branch, no ``nnkElse`` child exists.

Concrete syntax:

.. code-block:: nim
  if cond1:
    stmt1
  elif cond2:
    stmt2
  elif cond3:
    stmt3
  else:
    stmt4

AST:

.. code-block:: nim
  nnkIfStmt(
    nnkElifBranch(cond1, stmt1),
    nnkElifBranch(cond2, stmt2),
    nnkElifBranch(cond3, stmt3),
    nnkElse(stmt4)
  )


When statement
--------------

Like the ``if`` statement, but the root has the kind ``nnkWhenStmt``.


Assignment
----------

Concrete syntax:

.. code-block:: nim
  x = 42

AST:

.. code-block:: nim
  nnkAsgn(nnkIdent(!"x"), nnkIntLit(42))

This is not the syntax for assignment when combined with ``var``, ``let``,
or ``const``.

Statement list
--------------

Concrete syntax:

.. code-block:: nim
  stmt1
  stmt2
  stmt3

AST:

.. code-block:: nim
  nnkStmtList(stmt1, stmt2, stmt3)


Case statement
--------------

Concrete syntax:

.. code-block:: nim
  case expr1
  of expr2, expr3..expr4:
    stmt1
  of expr5:
    stmt2
  elif cond1:
    stmt3
  else:
    stmt4

AST:

.. code-block:: nim
  nnkCaseStmt(
    expr1,
    nnkOfBranch(expr2, nnkRange(expr3, expr4), stmt1),
    nnkOfBranch(expr5, stmt2),
    nnkElifBranch(cond1, stmt3),
    nnkElse(stmt4)
  )

The ``nnkElifBranch`` and ``nnkElse`` parts may be missing.


While statement
---------------

Concrete syntax:

.. code-block:: nim
  while expr1:
    stmt1

AST:

.. code-block:: nim
  nnkWhileStmt(expr1, stmt1)


For statement
-------------

Concrete syntax:

.. code-block:: nim
  for ident1, ident2 in expr1:
    stmt1

AST:

.. code-block:: nim
  nnkForStmt(ident1, ident2, expr1, stmt1)


Try statement
-------------

Concrete syntax:

.. code-block:: nim
  try:
    stmt1
  except e1, e2:
    stmt2
  except e3:
    stmt3
  except:
    stmt4
  finally:
    stmt5

AST:

.. code-block:: nim
  nnkTryStmt(
    stmt1,
    nnkExceptBranch(e1, e2, stmt2),
    nnkExceptBranch(e3, stmt3),
    nnkExceptBranch(stmt4),
    nnkFinally(stmt5)
  )


Return statement
----------------

Concrete syntax:

.. code-block:: nim
  return expr1

AST:

.. code-block:: nim
  nnkReturnStmt(expr1)


Yield statement
---------------

Like ``return``, but with ``nnkYieldStmt`` kind.

.. code-block:: nim
  nnkYieldStmt(expr1)


Discard statement
-----------------

Like ``return``, but with ``nnkDiscardStmt`` kind.

.. code-block:: nim
  nnkDiscardStmt(expr1)


Continue statement
------------------

Concrete syntax:

.. code-block:: nim
  continue

AST:

.. code-block:: nim
  nnkContinueStmt()

Break statement
---------------

Concrete syntax:

.. code-block:: nim
  break otherLocation

AST:

.. code-block:: nim
  nnkBreakStmt(nnkIdent(!"otherLocation"))

If ``break`` is used without a jump-to location, ``nnkEmpty`` replaces ``nnkIdent``.

Block statement
---------------

Concrete syntax:

.. code-block:: nim
  block name:

AST:

.. code-block:: nim
  nnkBlockStmt(nnkIdent(!"name"), nnkStmtList(...))

A ``block`` doesn't need an name, in which case ``nnkEmpty`` is used.

Asm statement
-------------

Concrete syntax:

.. code-block:: nim
  asm """
    some asm
  """

AST:

.. code-block:: nim
  nnkAsmStmt(
    nnkEmpty(), # for pragmas
    nnkTripleStrLit("some asm"),
  )

Import section
--------------

Nim's ``import`` statement actually takes different variations depending
on what keywords are present. Let's start with the simplest form.

Concrete syntax:

.. code-block:: nim
  import math

AST:

.. code-block:: nim
  nnkImportStmt(nnkIdent(!"math"))

With ``except``, we get ``nnkImportExceptStmt``.

Concrete syntax:

.. code-block:: nim
  import math except pow

AST:

.. code-block:: nim
  nnkImportExceptStmt(nnkIdent(!"math"),nnkIdent(!"pow"))

Note that ``import math as m`` does not use a different node; rather,
we use ``nnkImportStmt`` with ``as`` as an infix operator.

Concrete syntax:

.. code-block:: nim
  import strutils as su

AST:

.. code-block:: nim
  nnkImportStmt(
    nnkInfix(
      nnkIdent(!"as"),
      nnkIdent(!"strutils"),
      nnkIdent(!"su")
    )
  )

From statement
--------------

If we use ``from ... import``, the result is different, too.

Concrete syntax:

.. code-block:: nim
  from math import pow

AST:

.. code-block:: nim
  nnkFromStmt(nnkIdent(!"math"), nnkIdent(!"pow"))

Using ``from math as m import pow`` works identically to the ``as`` modifier
with the ``import`` statement, but wrapped in ``nnkFromStmt``.

Export statement
----------------

When you are making an imported module accessible by modules that import yours,
the ``export`` syntax is pretty straightforward.

Concrete syntax:

.. code-block:: nim
  export unsigned

AST:

.. code-block:: nim
  nnkExportStmt(nnkIdent(!"unsigned"))

Similar to the ``import`` statement, the AST is different for
``export ... except``.

Concrete syntax:

.. code-block:: nim
  export math except pow # we're going to implement our own exponentiation

AST:

.. code-block:: nim
  nnkExportExceptStmt(nnkIdent(!"math"),nnkIdent(!"pow"))

Include statement
-----------------

Like a plain ``import`` statement but with ``nnkIncludeStmt``.

Concrete syntax:

.. code-block:: nim
  include blocks

AST:

.. code-block:: nim
  nnkIncludeStmt(nnkIdent(!"blocks"))

Var section
-----------

Concrete syntax:

.. code-block:: nim
  var a = 3

AST:

.. code-block:: nim
  nnkVarSection(
    nnkIdentDefs(
      nnkIdent(!"a"),
      nnkEmpty(), # or nnkIdent(...) if the variable declares the type
      nnkIntLit(3),
    )
  )

Note that either the second or third (or both) parameters above must exist,
as the compiler needs to know the type somehow (which it can infer from
the given assignment).

This is not the same AST for all uses of ``var``. See
[Procedure declaration](http://nim-lang.org/docs/macros.html#statements-procedure-declaration)
for details.

Let section
-----------

This is equivalent to ``var``, but with ``nnkLetSection`` rather than
``nnkVarSection``.

Concrete syntax:

.. code-block:: nim
  let a = 3

AST:

.. code-block:: nim
  nnkLetSection(
    nnkIdentDefs(
      nnkIdent(!"a"),
      nnkEmpty(), # or nnkIdent(...) for the type
      nnkIntLit(3),
    )
  )

Const section
-------------

Concrete syntax:

.. code-block:: nim
  const a = 3

AST:

.. code-block:: nim
  nnkConstSection(
    nnkConstDef( # not nnkConstDefs!
      nnkIdent(!"a"),
      nnkEmpty(), # or nnkIdent(...) if the variable declares the type
      nnkIntLit(3), # required in a const declaration!
    )
  )

Type section
------------

Starting with the simplest case, a ``type`` section appears much like ``var``
and ``const``.

Concrete syntax:

.. code-block:: nim
  type A = int

AST:

.. code-block:: nim
  nnkTypeSection(
    nnkTypeDef(
      nnkIdent(!"A"),
      nnkEmpty(),
      nnkIdent(!"int")
    )
  )

Declaring ``distinct`` types is similar, with the last ``nnkIdent`` wrapped
in ``nnkDistinctTy``.

Concrete syntax:

.. code-block:: nim
  type MyInt = distinct int

AST:

.. code-block:: nim
  # ...
  nnkTypeDef(
    nnkIdent(!"MyInt"),
    nnkEmpty(),
    nnkDistinctTy(
      nnkIdent(!"int")
    )
  )

If a type section uses generic parameters, they are treated here:

Concrete syntax:

.. code-block:: nim
  type A[T] = expr1

AST:

.. code-block:: nim
  nnkTypeSection(
    nnkTypeDef(
      nnkIdent(!"A"),
      nnkGenericParams(
        nnkIdentDefs(
          nnkIdent(!"T"),
          nnkEmpty(), # if the type is declared with options, like
                      # ``[T: SomeInteger]``, they are given here
          nnkEmpty(),
        )
      )
      expr1,
    )
  )

Note that not all ``nnkTypeDef`` utilize ``nnkIdent`` as their
their parameter. One of the most common uses of type declarations
is to work with objects.

Concrete syntax:

.. code-block:: nim
  type IO = object of RootObj

AST:

.. code-block:: nim
  # ...
  nnkTypeDef(
    nnkIdent(!"IO"),
    nnkEmpty(),
    nnkObjectTy(
      nnkEmpty(), # no pragmas here
      nnkOfInherit(
        nnkIdent(!"RootObj") # inherits from RootObj
      )
      nnkEmpty()
    )
  )

Nim's object syntax is rich. Let's take a look at an involved example in
its entirety to see some of the complexities.

Concrete syntax:

.. code-block:: nim
  type Obj[T] = object {.inheritable.}
    name: string
    case isFat: bool
    of true:
      m: array[100_000, T]
    of false:
      m: array[10, T]

AST:

.. code-block:: nim
  # ...
  nnkObjectTy(
    nnkPragma(
      nnkIdent(!"inheritable")
    ),
    nnkEmpty(),
    nnkRecList( # list of object parameters
      nnkIdentDefs(
        nnkIdent(!"name"),
        nnkIdent(!"string"),
        nnkEmpty()
      ),
      nnkRecCase( # case statement within object (not nnkCaseStmt)
        nnkIdentDefs(
          nnkIdent(!"isFat"),
          nnkIdent(!"bool"),
          nnkEmpty()
        ),
        nnkOfBranch(
          nnkIdent(!"true"),
          nnkRecList( # again, a list of object parameters
            nnkIdentDefs(
              nnkIdent(!"m"),
              nnkBracketExpr(
                nnkIdent(!"array"),
                nnkIntLit(100000),
                nnkIdent(!"T")
              ),
              nnkEmpty()
          )
        ),
        nnkOfBranch(
          nnkIdent(!"false"),
          nnkRecList(
            nnkIdentDefs(
              nnkIdent(!"m"),
              nnkBracketExpr(
                nnkIdent(!"array"),
                nnkIntLit(10),
                nnkIdent(!"T")
              ),
              nnkEmpty()
            )
          )
        )
      )
    )
  )


Using an ``enum`` is similar to using an ``object``.

Concrete syntax:

.. code-block:: nim
  type X = enum
    First

AST:

.. code-block:: nim
  # ...
  nnkEnumTy(
    nnkEmpty(),
    nnkIdent(!"First") # you need at least one nnkIdent or the compiler complains
  )

The usage of ``concept`` (experimental) is similar to objects.

Concrete syntax:

.. code-block:: nim
  type Con = concept x,y,z
    (x & y & z) is string

AST:

.. code-block:: nim
  # ...
  nnkTypeClassTy( # note this isn't nnkConceptTy!
    nnkArglist(
      # ... idents for x, y, z
    )
    # ...
  )

Static types, like ``static[int]``, use ``nnkIdent`` wrapped in
``nnkStaticTy``.

Concrete syntax:

.. code-block:: nim
  type A[T: static[int]] = object

AST:

.. code-block:: nim
  # ... within nnkGenericParams
  nnkIdentDefs(
    nnkIdent(!"T"),
    nnkStaticTy(
      nnkIdent(!"int")
    ),
    nnkEmpty()
  )
  # ...

In general, declaring types mirrors this syntax (i.e., ``nnkStaticTy`` for
``static``, etc.). Examples follow (exceptions marked by ``*``):

-------------                ---------------------------------------------
Nim type                     Corresponding AST
-------------                ---------------------------------------------
``static``                   ``nnkStaticTy``
``tuple``                    ``nnkTupleTy``
``var``                      ``nnkVarTy``
``ptr``                      ``nnkPtrTy``
``ref``                      ``nnkRefTy``
``distinct``                 ``nnkDistinctTy``
``enum``                     ``nnkEnumTy``
``concept``                  ``nnkTypeClassTy``\*
``array``                    ``nnkBracketExpr(nnkIdent(!"array"),...``\*
``proc``                     ``nnkProcTy``
``iterator``                 ``nnkIteratorTy``
``object``                   ``nnkObjectTy``
-------------                ---------------------------------------------

Take special care when declaring types as ``proc``. The behavior is similar
to ``Procedure declaration``, below, but does not treat ``nnkGenericParams``.
Generic parameters are treated in the type, not the ``proc`` itself.

Concrete syntax:

.. code-block:: nim
  type MyProc[T] = proc(x: T)

AST:

.. code-block:: nim
  # ...
  nnkTypeDef(
    nnkIdent(!"MyProc"),
    nnkGenericParams( # here, not with the proc
      # ...
    )
    nnkProcTy( # behaves like a procedure declaration from here on
      nnkFormalParams(
        # ...
      )
    )
  )

The same syntax applies to ``iterator`` (with ``nnkIteratorTy``), but
*does not* apply to ``converter`` or ``template``.

Mixin statement
---------------

Concrete syntax:

.. code-block:: nim
  mixin x

AST:

.. code-block:: nim
  nnkMixinStmt(nnkIdent(!"x"))

Bind statement
--------------

Concrete syntax:

.. code-block:: nim
  bind x

AST:

.. code-block:: nim
  nnkBindStmt(nnkIdent(!"x"))

Procedure declaration
---------------------

Let's take a look at a procedure with a lot of interesting aspects to get
a feel for how procedure calls are broken down.

Concrete syntax:

.. code-block:: nim
  proc hello*[T: SomeInteger](x: int = 3, y: float32): int {.inline.} = discard

AST:

.. code-block:: nim
  nnkProcDef(
    nnkPostfix(nnkIdent(!"*"), nnkIdent(!"hello")), # the exported proc name
    nnkEmpty(), # patterns for term rewriting in templates and macros (not procs)
    nnkGenericParams( # generic type parameters, like with type declaration
      nnkIdentDefs(
        nnkIdent(!"T"), nnkIdent(!"SomeInteger")
      )
    ),
    nnkFormalParams(
      nnkIdent(!"int"), # the first FormalParam is the return type. nnkEmpty() if there is none
      nnkIdentDefs(
        nnkIdent(!"x"),
        nnkIdent(!"int"), # type type (required for procs, not for templates)
        nnkIntLit(3) # a default value
      ),
      nnkIdentDefs(
        nnkIdent(!"y"),
        nnkIdent(!"float32"),
        nnkEmpty()
      )
      nnkPragma(nnkIdent(!"inline")),
      nnkEmpty(), # reserved slot for future use
      nnkStmtList(nnkDiscardStmt(nnkEmpty())) # the meat of the proc
    )
  )

There is another consideration. Nim has flexible type identification for
its procs. Even though ``proc(a: int, b: int)`` and ``proc(a, b: int)``
are equivalent in the code, the AST is a little different for the latter.

Concrete syntax:

.. code-block:: nim
  proc(a, b: int)

AST:

.. code-block:: nim
  # ...AST as above...
  nnkFormalParams(
    nnkEmpty(), # no return here
    nnkIdentDefs(
      nnkIdent(!"a"), # the first parameter
      nnkIdent(!"b"), # directly to the second parameter
      nnkIdent(!"int"), # their shared type identifier
      nnkEmpty(), # default value would go here
    )
  ),
  # ...

When a procedure uses the special ``var`` type return variable, the result
is different from that of a var section.

Concrete syntax:

.. code-block:: nim
  proc hello(): var int

AST:

.. code-block:: nim
  # ...
  nnkFormalParams(
    nnkVarTy(
      nnkIdent(!"int")
    )
  )

Iterator declaration
--------------------

The syntax for iterators is similar to procs, but with ``nnkIteratorDef``
replacing ``nnkProcDef``.

Concrete syntax:

.. code-block:: nim
  iterator nonsense[T](x: seq[T]): float {.closure.} = ...

AST:

.. code-block:: nim
  nnkIteratorDef(
    nnkIdent(!"nonsense"),
    nnkEmpty(),
    ...
  )

Converter declaration
---------------------

A converter is similar to a proc.

Concrete syntax:

.. code-block:: nim
  converter toBool(x: float): bool

AST:

.. code-block:: nim
  nnkConverterDef(
    nnkIdent(!"toBool"),
    # ...
  )

Template declaration
--------------------

Templates (as well as macros, as we'll see) have a slightly expanded AST when
compared to procs and iterators. The reason for this is [term-rewriting
macros](http://nim-lang.org/docs/manual.html#term-rewriting-macros). Notice
the ``nnkEmpty()`` as the second argument to ``nnkProcDef`` and
``nnkIteratorDef`` above? That's where the term-rewriting macros go.

Concrete syntax:

.. code-block:: nim
  template optOpt{expr1}(a: int): int

AST:

.. code-block:: nim
  nnkTemplateDef(
    nnkIdent(!"optOpt"),
    nnkStmtList( # instead of nnkEmpty()
      expr1
    ),
    # follows like a proc or iterator
  )

If the template does not have types for its parameters, the type identifiers
inside ``nnkFormalParams`` just becomes ``nnkEmpty``.

Macro declaration
-----------------

Macros behave like templates, but ``nnkTemplateDef`` is replaced with
``nnkMacroDef``.


Special node kinds
==================

There are several node kinds that are used for semantic checking or code
generation. These are accessible from this module, but should not be used.
Other node kinds are especially designed to make AST manipulations easier.
These are explained here.

To be written.
]#
