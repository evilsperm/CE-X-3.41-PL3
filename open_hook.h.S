#include "macros.h.S"
// need to -1 to not count trailing \x00 from paths
#define BDVD_PATH_LEN (bdvd_path_end - bdvd_path - 1)
#define APP_PATH_LEN (app_path_end - app_path - 1)
#define USB_PATH_LEN (usb_path_end - usb_path - 1)

/**
 * hook_open:
 * @path: The path to open
 * @mode: The mode to use for opening the file
 *
 * This hook replaces the open syscall and will replace the path used
 * for file open when the game_path is set to allow for bdvd emulation
 *
 *  hook_open (path, mode):
 *  {
 *    if (strncmp(path, "/app_home", 9) == 0) {
 *      if (game_path != NULL) {
 *        strcpy (game_path_end, path + 9);
 *        path = game_path;
 *      } else {
 *        strcpy (game_app_path + 11, path + 9);
 *        path = game_app_path;
 *      }
 *    } else if (strncmp(path, "/dev_bdvd", 9) == 0 && game_path != NULL) {
 *      strcpy (game_path_end, path + 9)
 *      path = game_path;
 *    }
 *
 *    return original_open (path, mode);
 *  }
 */
.align 4
hook_open:
	// This is a copy from the original hook function, setting up the stack
	stdu	%r1, -0xa0(%r1)
	mflr	%r0
	std	%r28, 0x80(%r1)
	std	%r29, 0x88(%r1)
	std	%r31, 0x98(%r1)
	std	%r26, 0x70(%r1)
	std	%r27, 0x78(%r1)
	std	%r0, 0xb0(%r1)
	mr	%r28, %r4
	mr	%r29, %r3
	
	// Actual payload code
	MEM_BASE (%r31)
	LOAD_LABEL2 (%r4, %r31, app_path)
	li	%r5, APP_PATH_LEN
	bl	ABSOLUTE_MEM2(strncmp)
	cmpldi	%r3, 0
	bne	l_bdvd_open
l_app_open:
	LOAD_LABEL2(%r4, %r31, game_app_path)
	ld	%r27, 0(%r4)
	addi	%r3, %r27, USB_PATH_LEN
	LOAD_LABEL2(%r5, %r31, game_path)
	ld	%r4, 0(%r5)
	cmpldi	%r4, 0
	beq	l_app_copy_path
	mr	%r27, %r4
	ld	%r3, 8(%r5)
l_app_copy_path:
	addi	%r4, %r29, APP_PATH_LEN
	bl	ABSOLUTE_MEM2(strcpy)
	mr	%r29, %r27
	b	l_proceed
l_bdvd_open:
	mr	%r3, %r29
	LOAD_LABEL2(%r4, %r31, bdvd_path)
	li	%r5, BDVD_PATH_LEN
	bl	ABSOLUTE_MEM2(strncmp)
	cmpldi	%r3, 0
	bne	l_proceed
	LOAD_LABEL2(%r31, %r31, game_path)


//#ifdef USB_MODULE
//	lwz     %r3, 0x10(%r31)
//	cmplwi  %r3, 0
//	beq     l_proceed
//#endif

	ld	%r3, 0(%r31)
	cmpldi	%r3, 0
	beq	l_proceed
	ld	%r3, 8(%r31)
	addi	%r4, %r29, BDVD_PATH_LEN
	bl	ABSOLUTE_MEM2(strcpy)
	ld	%r29, 0(%r31)
l_proceed:
	mr	%r3, %r29
	b       ABSOLUTE_MEM2(patch_func3 + 0x28)

bdvd_path:
	.string "/dev_bdvd"
bdvd_path_end:
app_path:
	.string "/app_home"
app_path_end:
usb_path:
	.string "/dev_usb000"
usb_path_end:

game_path:
	.quad	0
game_path_end:
	.quad	0
game_app_path:
	.quad	0
