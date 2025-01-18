#include <Eigen/Dense>
#include <vector>
#include <iostream>

int main() {
    // Example 1D vector of weights
    std::vector<double> weights = {1.0, 2.0, 3.0};

    // Get the size of the weights vector
    int N = weights.size();

    // Convert the weights vector to an Eigen::VectorXd and then to a diagonal matrix
    Eigen::MatrixXd W = Eigen::VectorXd::Map(weights.data(), N).asDiagonal();

    // Print the resulting diagonal matrix W
    std::cout << "Diagonal Matrix W:\n" << W << std::endl;

    return 0;
}
