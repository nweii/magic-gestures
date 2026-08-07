// Reports whether macOS currently considers Secure Input active.

#import <Carbon/Carbon.h>
#import <stdio.h>

int main(void) {
    printf("%s\n", IsSecureEventInputEnabled() ? "enabled" : "disabled");
    return 0;
}
