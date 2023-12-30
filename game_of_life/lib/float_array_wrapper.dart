import 'dart:ffi';
// import 'package:ffi/ffi.dart';

// Define the types of your C functions
typedef _CreateFloatArrayNative = Pointer<Float> Function(Int32 size);
typedef _CreateFloatArrayDart = Pointer<Float> Function(int size);

typedef _DeleteFloatArrayNative = Void Function(Pointer<Float> array);
typedef _DeleteFloatArrayDart = void Function(Pointer<Float> array);

typedef _ModifyArrayNative = Void Function(Pointer<Float> array, Int32 size);
typedef _ModifyArrayDart = void Function(Pointer<Float> array, int size);

class FloatArrayWrapper {
  late final Pointer<Float> _pointer;
  late final int _size;
  late final _DeleteFloatArrayDart _deleteFloatArray;
  late final Finalizer<Pointer<Float>> _finalizer;

  // Load the shared library and lookup the functions
  FloatArrayWrapper(int size) {
    final dylib = DynamicLibrary.open("path_to_your_shared_library");

    final createFloatArray = dylib
        .lookupFunction<_CreateFloatArrayNative, _CreateFloatArrayDart>("createFloatArray");
    _deleteFloatArray = dylib
        .lookupFunction<_DeleteFloatArrayNative, _DeleteFloatArrayDart>("deleteFloatArray");
    final modifyArray = dylib
        .lookupFunction<_ModifyArrayNative, _ModifyArrayDart>("modifyArray");

    _pointer = createFloatArray(size);
    _size = size;

    // Registering finalizer with the correct type
    _finalizer = Finalizer<Pointer<Float>>((pointer) => _deleteFloatArray(pointer));
    _finalizer.attach(this, _pointer, detach: this);

    // Example usage of another function
    modifyArray(_pointer, _size);
  }

  // Get value at a specific index
  double getValue(int index) {
    _validateIndex(index);
    return _pointer.elementAt(index).value;
  }

  // Set value at a specific index
  void setValue(int index, double value) {
    _validateIndex(index);
    _pointer.elementAt(index).value = value;
  }

  // Utility method to validate index
  void _validateIndex(int index) {
    if (index < 0 || index >= _size) {
      throw RangeError.index(index, this, 'index', 'Invalid index', _size);
    }
  }

  // Convert the native array to a Dart List
  List<double> toList() {
    return List<double>.generate(_size, (i) => getValue(i));
  }

  // Method to manually release the native resource
  void dispose() {
    if (_pointer.address != 0) {
      _deleteFloatArray(_pointer);
      _pointer = Pointer.fromAddress(0);
    }
  }
}
