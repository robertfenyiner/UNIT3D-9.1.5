// Fantasma JS basado en https://codepen.io/theArtsy07/pen/WNmVyPb
document.addEventListener('DOMContentLoaded', function () {
    const ghost = document.createElement('div');
    ghost.className = 'ghost';
    ghost.innerHTML = `
      <div class="ghost-body"></div>
      <div class="ghost-face">
        <div class="ghost-eye"></div>
        <div class="ghost-eye"></div>
      </div>
      <div class="ghost-mouth"></div>
      <div class="ghost-bottom">
        <span></span><span></span><span></span><span></span><span></span>
      </div>
    `;
    document.body.appendChild(ghost);

    let mouseX = window.innerWidth / 2;
    let mouseY = window.innerHeight / 2;
    let ghostX = mouseX;
    let ghostY = mouseY;

    document.addEventListener('mousemove', function (e) {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

  const ghostWidth = 80;
  const ghostHeight = 80;
  function animate() {
    ghostX += (mouseX - ghostX) * 0.15;
    ghostY += (mouseY - ghostY) * 0.15;
    // Centrar el fantasma en el cursor
    ghost.style.transform = `translate(${ghostX - ghostWidth/2}px, ${ghostY - ghostHeight/2}px)`;
    requestAnimationFrame(animate);
  }
  animate();
});
