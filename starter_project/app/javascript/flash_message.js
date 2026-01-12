// Flash message popup handler
// Automatically dismisses flash messages after a timeout
// Allows manual dismissal via close button

(function() {
  const flashMessage = document.getElementById('flash-message');
  const closeButton = document.getElementById('flash-close');

  if (!flashMessage) return;

  // Auto-dismiss after 5 seconds
  const autoDismiss = setTimeout(() => {
    dismissFlash();
  }, 5000);

  // Manual dismiss via close button
  if (closeButton) {
    closeButton.addEventListener('click', () => {
      clearTimeout(autoDismiss);
      dismissFlash();
    });
  }

  // Dismiss animation
  function dismissFlash() {
    flashMessage.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out';
    flashMessage.style.opacity = '0';
    flashMessage.style.transform = 'translateX(100%)';
    
    setTimeout(() => {
      flashMessage.remove();
    }, 300);
  }
})();
