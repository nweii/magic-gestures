// Releases a potentially stuck synthetic right-Control modifier and exits.

#import <ApplicationServices/ApplicationServices.h>
#import <unistd.h>

int main(void) {
    CGEventRef event = CGEventCreateKeyboardEvent(NULL, 62, false);
    if (event == NULL)
        _exit(1);
    CGEventSetFlags(event, 0);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
    _exit(0);
}
