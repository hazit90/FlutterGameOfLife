
extern "C" {
    float* createFloatArray(int size) {
        return new float[size];
    }

    void deleteFloatArray(float* array) {
        delete[] array;
    }

    // Example function that modifies the array
    void modifyArray(float* array, int size) {
        for (int i = 0; i < size; ++i) {
            array[i] = static_cast<float>(i);
        }
    }
}
