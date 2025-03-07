import numpy as np
import matplotlib.pyplot as plt

# Define the function f(x) = 2x^2 + 7x + 3
def f(x):
    return 2*x**2 + 7*x + 3

# Generate x values from -5 to 1 for better visualization of the vertex and roots
x = np.linspace(-5, 1, 400)
y = f(x)

# Calculate vertex and roots
vertex_x = -7 / (2 * 2)  # x-coordinate of vertex is -b/(2a)
vertex_y = f(vertex_x)   # y-coordinate of vertex

# Roots (from previous calculation: x = -1/2 and x = -3)
roots = [-3, -0.5]

# Plot the graph
plt.figure(figsize=(8, 6))
plt.plot(x, y, label=r"$f(x) = 2x^2 + 7x + 3$", color="blue")
plt.axhline(0, color='black', linewidth=0.8, linestyle='--')
plt.axvline(0, color='black', linewidth=0.8, linestyle='--')

# Highlight the vertex
plt.scatter(vertex_x, vertex_y, color="red", label=f"Vertex ({vertex_x:.2f}, {vertex_y:.2f})")

# Highlight the roots
plt.scatter(roots, [0, 0], color="green", label="Roots (-3, -1/2)")

# Add labels and title
plt.title("Graph of $f(x) = 2x^2 + 7x + 3$", fontsize=14)
plt.xlabel("$x$", fontsize=12)
plt.ylabel("$f(x)$", fontsize=12)
plt.legend()
plt.grid(alpha=0.3)

# Show the graph
plt.show()
