// Tensor.cuh
#ifndef TENSOR_CUH
#define TENSOR_CUH

#include "OperationKernels.cuh"
#include <iterator>
#include <stdexcept>
#include <curand.h>
#include <vector>
#include <iostream>
#include "dl_export.cuh"

namespace NeuZephyr::Data {
    class DL_API Tensor {
    public:
        using size_type = unsigned long long;
        using value_type = float;
        using shape_type = std::vector<int>;

        friend DL_API std::ostream& operator<<(std::ostream& os, const Tensor& tensor);
        friend DL_API std::istream& operator>>(std::istream& is, const Tensor& tensor);
        friend DL_API Tensor operator*(value_type lhs, const Tensor& rhs);
        friend DL_API Tensor operator*(const Tensor& lhs, value_type rhs);
        friend DL_API Tensor operator/(const Tensor& lhs, value_type rhs);
        friend DL_API Tensor operator+(const Tensor& lhs, value_type rhs);
        friend DL_API Tensor operator+(value_type lhs, const Tensor& rhs);
        friend DL_API Tensor operator-(const Tensor& lhs, value_type rhs);
        friend DL_API Tensor operator-(value_type lhs, const Tensor& rhs);
        friend DL_API Tensor ReLU(const Tensor& tensor);
        friend DL_API Tensor Sigmoid(const Tensor& tensor);
        friend DL_API Tensor Tanh(const Tensor& tensor);
        friend DL_API Tensor LeakyReLU(const Tensor& tensor, float alpha = 0.01f);
        friend DL_API Tensor Swish(const Tensor& tensor);
        friend DL_API Tensor ELU(const Tensor& tensor, float alpha = 1.0f);
        friend DL_API Tensor HardSigmoid(const Tensor& tensor, float alpha = 0.2f, float beta = 0.5f);
        friend DL_API Tensor HardSwish(const Tensor& tensor, float alpha = 0.2f, float beta = 0.5f);
        friend DL_API Tensor Softmax(const Tensor& tensor);

        // Constructors
        Tensor();
        explicit Tensor(const shape_type& shape, const bool requires_grad = false);
        explicit Tensor(const shape_type& shape, const value_type* data, const bool requires_grad = false);
        explicit Tensor(const std::initializer_list<int>& shape, const bool requires_grad = false);
        explicit Tensor(const std::initializer_list<int>& shape, const value_type* data,
                        const bool requires_grad = false);

        template <typename Iterator>
        Tensor::Tensor(const shape_type shape, Iterator first, Iterator last, const bool requires_grad) :
            _size(std::distance(first, last)), _shape(shape), _requires_grad(requires_grad) {
            if (shape[0] * shape[1] != _size) {
                throw std::invalid_argument("The size of the data does not match the shape.");
            }
            cudaMalloc((value_type**)&_data, _size * sizeof(value_type));
            cudaMemcpy(_data, first, _size * sizeof(value_type), cudaMemcpyDeviceToDevice);
            if (_requires_grad) {
                cudaMalloc((value_type**)&_grad, _size * sizeof(value_type));
            }
        }

        template <typename Iterator>
        Tensor::Tensor(const std::initializer_list<int>& shape, Iterator first, Iterator last,
                       const bool requires_grad) :
            _size(std::distance(first, last)), _shape(shape), _requires_grad(requires_grad) {
            if (_shape[0] * _shape[1] != _size) {
                throw std::invalid_argument("The size of the data does not match the shape.");
            }
            cudaMalloc((value_type**)&_data, _size * sizeof(value_type));
            cudaMemcpy(_data, first, _size * sizeof(value_type), cudaMemcpyDeviceToDevice);
            if (_requires_grad) {
                cudaMalloc((value_type**)&_grad, _size * sizeof(value_type));
            }
        }

        // Copy and Move
        Tensor(const Tensor& other);
        Tensor(Tensor&& other) noexcept;
        Tensor& operator=(const Tensor& other);
        Tensor& operator=(Tensor&& other) noexcept;
        ~Tensor();

        // Getters and Setters
        bool requiresGrad() const noexcept;
        shape_type shape() const noexcept;
        size_type size() const noexcept;
        void setRequiresGrad(const bool requires_grad) noexcept;

        // Operations
        void zeroGrad() const noexcept;
        void print() const noexcept;
        void copyData(const value_type* data, const shape_type& shape);
        void copyGrad(const value_type* grad) const;
        void randomize(unsigned long long seed = 0) const;
        void clear() const;
        void fill(const value_type value) const;
        void fillGrad(const value_type value) const;

        // Operators
        Tensor operator+(const Tensor& other) const;
        Tensor operator-(const Tensor& other) const;
        Tensor operator*(const Tensor& other) const;

        void reshape(const shape_type& shape);
        void reshape(const std::initializer_list<int>& shape);
        void transpose();
        void setData(const shape_type& position, const value_type value) const;
        void setData(const std::initializer_list<int>& position, const value_type value) const;
        value_type* data() const noexcept;
        value_type* grad() const noexcept;
        std::ostream& printGrad(std::ostream& os) const;
        Tensor operator-() const;
        void recip() const;

    private:
        size_type _size;
        shape_type _shape;
        value_type* _data;
        value_type* _grad;
        bool _requires_grad;
    };
}

#endif //TENSOR_CUH
