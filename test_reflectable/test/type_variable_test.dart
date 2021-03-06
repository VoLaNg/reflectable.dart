// Copyright (c) 2015, the Dart Team. All rights reserved. Use of this
// source code is governed by a BSD-style license that can be found in
// the LICENSE file.

// File used to test reflectable code generation.
// Uses type variables.

library test_reflectable.test.type_variable_test;

import 'package:reflectable/reflectable.dart';
import 'package:test/test.dart';
import 'type_variable_test.reflectable.dart';

class NoTypeVariablesReflector extends Reflectable {
  const NoTypeVariablesReflector()
      : super(libraryCapability, typeRelationsCapability);
}

class NoBoundsReflector extends Reflectable {
  const NoBoundsReflector()
      : super(
            declarationsCapability, typeRelationsCapability, libraryCapability);
}

class Reflector extends Reflectable {
  const Reflector()
      : super(typeAnnotationQuantifyCapability, declarationsCapability,
            libraryCapability, typeRelationsCapability, metadataCapability);
}

const Reflectable noTypeVariablesReflector = NoTypeVariablesReflector();
const Reflectable noBoundsReflector = NoBoundsReflector();
const Reflectable reflector = Reflector();

class A {}

@noTypeVariablesReflector
@noBoundsReflector
@reflector
class B<X, Y extends A> {}

@reflector
class C<Z extends A> extends B<List<Z>, Z> implements A {}

@reflector
class D<U extends C<U>> extends C<U> {}

@reflector
class E extends C<E> {}

void runTestNoBounds(String message, ClassMirror classMirror) {
  test('Type variables, no bounds capability, $message', () {
    expect(classMirror.typeVariables.length, 2);

    var xMirror = classMirror.typeVariables[0];
    expect(xMirror.simpleName, 'X');
    expect(
        xMirror.qualifiedName, 'test_reflectable.test.type_variable_test.B.X');
    expect(xMirror.owner, classMirror.originalDeclaration);
    expect(xMirror.isPrivate, false);
    expect(xMirror.isTopLevel, false);
    expect(() => xMirror.metadata, throwsANoSuchCapabilityException);
    expect(() => xMirror.upperBound, throwsANoSuchCapabilityException);
    expect(xMirror.isStatic, false);

    var yMirror = classMirror.typeVariables[1];
    expect(yMirror.simpleName, 'Y');
    expect(
        yMirror.qualifiedName, 'test_reflectable.test.type_variable_test.B.Y');
    expect(yMirror.owner, classMirror.originalDeclaration);
    expect(yMirror.isPrivate, false);
    expect(yMirror.isTopLevel, false);
    expect(() => yMirror.metadata, throwsANoSuchCapabilityException);
    expect(() => yMirror.upperBound, throwsANoSuchCapabilityException);
    expect(yMirror.isStatic, false);
  });
}

void runTest(String message, ClassMirror bMirror, ClassMirror cMirror,
    ClassMirror dMirror, ClassMirror eMirror) {
  // Things not already tested in `runTestNoBounds`: Upper bounds and metadata.
  test('Type variables, $message', () {
    expect(bMirror.typeVariables.length, 2);
    expect(cMirror.typeVariables.length, 1);
    expect(dMirror.typeVariables.length, 1);
    expect(eMirror.typeVariables.length, 0);

    var bParameter0Mirror = bMirror.typeVariables[0];
    var bParameter1Mirror = bMirror.typeVariables[1];
    var cParameterMirror = cMirror.typeVariables[0];
    var dParameterMirror = dMirror.typeVariables[0];

    expect(bParameter0Mirror.upperBound.reflectedType, Object);
    expect(bParameter1Mirror.upperBound.reflectedType, A);
    expect(cParameterMirror.upperBound.reflectedType, A);
    expect(dParameterMirror.upperBound.originalDeclaration,
        cMirror.originalDeclaration);

    expect(bParameter0Mirror.metadata, <Object>[]);
    expect(bParameter1Mirror.metadata, <Object>[]);
    expect(cParameterMirror.metadata, <Object>[]);
    expect(dParameterMirror.metadata, <Object>[]);
  });
}

Matcher throwsANoSuchCapabilityException =
    throwsA(const TypeMatcher<NoSuchCapabilityError>());

void main() {
  initializeReflectable();

  var b = B<int, A>();

  test('Type variables, no type variable capability', () {
    var classMirror = noTypeVariablesReflector.reflect(b).type;
    expect(() => classMirror.typeVariables, throwsANoSuchCapabilityException);
  });

  var noBoundsLibraryMirror =
      noBoundsReflector.findLibrary('test_reflectable.test.type_variable_test');
  runTestNoBounds('generic class', noBoundsLibraryMirror.declarations['B']);
  runTestNoBounds(
      'instantiated generic class', noBoundsReflector.reflect(b).type);

  var libraryMirror =
      reflector.findLibrary('test_reflectable.test.type_variable_test');
  runTest(
      'static',
      libraryMirror.declarations['B'],
      libraryMirror.declarations['C'],
      libraryMirror.declarations['D'],
      libraryMirror.declarations['E']);

  runTest(
      'dynamic',
      reflector.reflect(B<int, A>()).type,
      reflector.reflect(C<A>()).type,
      reflector.reflect(D<E>()).type,
      reflector.reflect(E()).type);
}
