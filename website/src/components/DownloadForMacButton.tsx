import { Button, type ButtonVariant } from "@/components/ds/primitives";
import { getPayhipCheckoutUrl } from "@/lib/payhip-checkout";

type DownloadForMacButtonProps = {
  variant?: ButtonVariant;
  size?: "sm" | "md" | "lg";
  className?: string;
};

export function DownloadForMacButton({
  variant = "cream",
  size = "lg",
  className = "",
}: DownloadForMacButtonProps) {
  const checkoutUrl = getPayhipCheckoutUrl();

  if (checkoutUrl) {
    return (
      <Button
        href={checkoutUrl}
        variant={variant}
        size={size}
        className={className}
        target="_blank"
        rel="noopener noreferrer"
      >
        Download for Mac
      </Button>
    );
  }

  return (
    <Button variant={variant} size={size} className={className}>
      Download for Mac
    </Button>
  );
}
