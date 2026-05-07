import pygame
import sys

# Initialize Pygame
pygame.init()

# Set up screen dimensions and display
screen_width = 600
screen_height = 600
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Tic-Tac-Toe")

# Colors
WHITE = (255, 255, 255)
LINE_COLOR = (0, 0, 0)
X_COLOR = (28, 170, 156)
O_COLOR = (242, 85, 96)

# Game variables
GRID_SIZE = 3
CELL_SIZE = screen_width // GRID_SIZE
GRID = [[None for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]
turn = "X"  # X starts the game

# Fonts
font = pygame.font.SysFont("Arial", 40)

# Function to draw the grid
def draw_grid():
    for row in range(1, GRID_SIZE):
        pygame.draw.line(screen, LINE_COLOR, (0, row * CELL_SIZE), (screen_width, row * CELL_SIZE), 3)
        pygame.draw.line(screen, LINE_COLOR, (row * CELL_SIZE, 0), (row * CELL_SIZE, screen_height), 3)

# Function to draw X and O
def draw_XO():
    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            if GRID[row][col] == "X":
                pygame.draw.line(screen, X_COLOR, 
                                 (col * CELL_SIZE + 50, row * CELL_SIZE + 50), 
                                 (col * CELL_SIZE + CELL_SIZE - 50, row * CELL_SIZE + CELL_SIZE - 50), 5)
                pygame.draw.line(screen, X_COLOR, 
                                 (col * CELL_SIZE + CELL_SIZE - 50, row * CELL_SIZE + 50), 
                                 (col * CELL_SIZE + 50, row * CELL_SIZE + CELL_SIZE - 50), 5)
            elif GRID[row][col] == "O":
                pygame.draw.circle(screen, O_COLOR, 
                                   (col * CELL_SIZE + CELL_SIZE // 2, row * CELL_SIZE + CELL_SIZE // 2), 50, 5)

# Function to check for a win
def check_win():
    for row in range(GRID_SIZE):
        if GRID[row][0] == GRID[row][1] == GRID[row][2] != None:
            return True
    for col in range(GRID_SIZE):
        if GRID[0][col] == GRID[1][col] == GRID[2][col] != None:
            return True
    if GRID[0][0] == GRID[1][1] == GRID[2][2] != None:
        return True
    if GRID[0][2] == GRID[1][1] == GRID[2][0] != None:
        return True
    return False

# Function to check if the game is a draw
def check_draw():
    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            if GRID[row][col] == None:
                return False
    return True

# Function to display the winner message
def display_winner(winner):
    text = font.render(f"Player {winner} wins!", True, (0, 255, 0))
    screen.blit(text, (screen_width // 2 - text.get_width() // 2, screen_height // 2 - 50))

# Function to display a draw message
def display_draw():
    text = font.render("It's a Draw!", True, (255, 0, 0))
    screen.blit(text, (screen_width // 2 - text.get_width() // 2, screen_height // 2 - 50))

# Main game loop
def main():
    global turn
    game_over = False

    while True:
        screen.fill(WHITE)
        draw_grid()
        draw_XO()

        if game_over:
            pygame.display.update()
            pygame.time.wait(2000)
            break

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            if event.type == pygame.MOUSEBUTTONDOWN:
                if not game_over:
                    col = event.pos[0] // CELL_SIZE
                    row = event.pos[1] // CELL_SIZE

                    if GRID[row][col] is None:
                        GRID[row][col] = turn
                        if check_win():
                            display_winner(turn)
                            game_over = True
                        elif check_draw():
                            display_draw()
                            game_over = True
                        turn = "O" if turn == "X" else "X"

        pygame.display.update()

if __name__ == "__main__":
    main()