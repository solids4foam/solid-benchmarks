#include <iostream>
#include <vector>
#include <Eigen/Dense>  // Requires Eigen library

using namespace std;
using namespace Eigen;

Vector3d compute_weighted_gradient
(
    const vector<Vector3d>& stencil_points, 
    const vector<double>& function_values, 
    const vector<double>& weights
)
{
    int N = stencil_points.size();
    //const int N = 27;

    // Design matrix A for quadratic polynomial fit
    MatrixXd A(N, 10);
    
    for (int i = 0; i < N; ++i)
    {
        double x = stencil_points[i](0) ;
        double y = stencil_points[i](1) ;
        double z = stencil_points[i](2) ;
        A(i, 0) = 1.0;       // constant term
        A(i, 1) = x;         // linear x term
        A(i, 2) = y;         // linear y term
        A(i, 3) = z;         // linear z term
        A(i, 4) = x * x;     // quadratic x^2 term
        A(i, 5) = x * y;     // quadratic xy term
        A(i, 6) = x * z;     // quadratic xz term
        A(i, 7) = y * y;     // quadratic y^2 term
        A(i, 8) = y * z;     // quadratic yz term
        A(i, 9) = z * z;     // quadratic z^2 term
    }
    
    // Convert function_values to Eigen vector
    VectorXd b = VectorXd::Map(function_values.data(), N);

    // Create the weight matrix W as a diagonal matrix
    // VectorXd weightsVec = VectorXd::Map(weights.data(), N);
    // auto W = weightsVec.asDiagonal();
    auto W = VectorXd::Map(weights.data(), N).asDiagonal();
    
    // Solve the weighted least squares problem using QR decomposition
    VectorXd coeffs = (W * A).householderQr().solve(W * b);
    
    // Gradient at the center (x=0, y=0, z=0) is (a1, a2, a3)
    Vector3d gradient;
    gradient << coeffs(1), coeffs(2), coeffs(3);
    
    return gradient;
}

int main()
{
    std::cout<< "Start" << std::endl;

    // Example usage: 27-point stencil in 3D
    vector<Vector3d> stencil_points = {
        {-1, -1, -1}, { 0, -1, -1}, { 1, -1, -1},
        {-1,  0, -1}, { 0,  0, -1}, { 1,  0, -1},
        {-1,  1, -1}, { 0,  1, -1}, { 1,  1, -1},

        {-1, -1,  0}, { 0, -1,  0}, { 1, -1,  0},
        {-1,  0,  0}, { 0,  0,  0}, { 1,  0,  0},
        {-1,  1,  0}, { 0,  1,  0}, { 1,  1,  0},

        {-1, -1,  1}, { 0, -1,  1}, { 1, -1,  1},
        {-1,  0,  1}, { 0,  0,  1}, { 1,  0,  1},
        {-1,  1,  1}, { 0,  1,  1}, { 1,  1,  1}
    };
    
    vector<double> function_values = {
        1, 2, 1,
        1, 3, 2,
        1, 2, 1,

        2, 3, 2,
        2, 4, 3,
        2, 3, 2,

        3, 20, 10,
        3, 30, 20,
        3, 20, 10
    };

    // Example weights: all weights equal to 1
    std::cout<< "W" << std::endl;
    //vector<double> weights(27, 1.0);  // Change these values based on the importance of each stencil point
    vector<double> weights = {1,1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,1,};

    std::cout<< "grad s" << std::endl;
    Vector3d gradient = compute_weighted_gradient(stencil_points, function_values, weights);
    std::cout<< "grad e" << std::endl;
    
    cout << "Weighted Gradient at the center of the stencil: (" 
         << gradient(0) << ", " << gradient(1) << ", " << gradient(2) << ")" << endl;
    
    return 0;
}
