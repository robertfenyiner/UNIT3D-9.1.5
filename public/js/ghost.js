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

    function animate() {
        ghostX += (mouseX - ghostX) * 0.15;
        ghostY += (mouseY - ghostY) * 0.15;
        ghost.style.transform = `translate(-50%, -50%) translate(${ghostX}px, ${ghostY}px)`;
        requestAnimationFrame(animate);
    }
    animate();
});
