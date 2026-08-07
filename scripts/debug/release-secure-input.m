// Releases one orphaned macOS Secure Input claim and reports the resulting state.

#import <Carbon/Carbon.h>
#import <stdio.h>

int main(void) {
    if (IsSecureEventInputEnabled())
        DisableSecureEventInput();
    printf("%s\n", IsSecureEventInputEnabled() ? "enabled" : "disabled");
    return 0;
}
