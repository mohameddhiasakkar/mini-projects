import pygame
import sys

# Initialize Pygame
pygame.init()

# Set up the screen and colors
screen_width = 400
screen_height = 600
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Calculator")

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (169, 169, 169)
LIGHT_GRAY = (211, 211, 211)

# Fonts
font = pygame.font.SysFont("Arial", 32)
small_font = pygame.font.SysFont("Arial", 24)

# Set up the calculator variables
input_text = ""
output_text = ""
button_width = screen_width // 4
button_height = screen_height // 8

# Define button layout (Button labels)
buttons = [
    ('7', '8', '9', '/'),
    ('4', '5', '6', '*'),
    ('1', '2', '3', '-'),
    ('C', '0', '=', '+')
]

# Draw the screen
def draw_screen():
    screen.fill(WHITE)
    
    # Draw the input and output fields
    input_display = font.render(input_text, True, BLACK)
    output_display = font.render(output_text, True, BLACK)
    
    screen.blit(input_display, (20, 20))
    screen.blit(output_display, (20, 80))

    # Draw buttons
    for row in range(4):
        for col in range(4):
            button_text = buttons[row][col]
            button_rect = pygame.Rect(col * button_width, (row + 2) * button_height, button_width, button_height)
            pygame.draw.rect(screen, LIGHT_GRAY, button_rect, border_radius=10)
            pygame.draw.rect(screen, BLACK, button_rect, 3, border_radius=10)
            text = small_font.render(button_text, True, BLACK)
            screen.blit(text, (button_rect.x + button_rect.width // 2 - text.get_width() // 2,
                               button_rect.y + button_rect.height // 2 - text.get_height() // 2))

def evaluate_expression():
    try:
        return str(eval(input_text))  # Calculate the result
    except:
        return "Error"

def main():
    global input_text, output_text

    running = True
    while running:
        draw_screen()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

            if event.type == pygame.MOUSEBUTTONDOWN:
                x, y = event.pos
                col = x // button_width
                row = (y - 180) // button_height

                if 0 <= row < 4 and 0 <= col < 4:
                    button = buttons[row][col]

                    if button == 'C':
                        input_text = ""
                    elif button == '=':
                        output_text = evaluate_expression()
                        input_text = ""
                    else:
                        input_text += button

        pygame.display.update()

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()